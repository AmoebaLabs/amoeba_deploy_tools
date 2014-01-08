require 'json'

module AmoebaDeployTools
  class Node < Command
    include AmoebaDeployTools::Concerns::SSH

    desc 'bootstrap', 'Setup the node initially (run the first time you want to deploy a node)'
    long_desc <<-LONGDESC
      `bootstrap` will load Chef and the `basenode` recipe on the node. This is effectively the way
      to setup a node initially. Subsequent runs can use the `node push` command.
    LONGDESC
    option :version, desc: 'Chef version to bootstrap', default: '11.8.2'
    option :interactive, desc: 'Run interactively (useful for entering passwords)', type: :boolean, default: false
    def bootstrap
      logger.info 'Starting `bootstrap`!'

      refresh
      knife_solo :prepare, 'bootstrap-version' => options[:version], ssh: true, interactive: options[:interactive]

      knife_solo :cook, ssh: true, include_private_key: true, interactive: options[:interactive] do |j|
        j.run_list = ['role[base]']
      end

      force_deployer

      pull

      logger.warn 'Node bootstrapped successfully, you can now push to the node:'
      logger.warn "\tamoeba node push --node #{options[:node]}\n"
    end

    desc 'force_deployer', 'Forces the deploy user to be `deploy` or that specified in node.json'
    def force_deployer
      logger.info 'Starting force_deployer'
      data_bag(:nodes)[node.name] = { deployment: { user: node.depoyment_.user || 'deploy' } }
    end

    desc 'push', 'Push any changes to the node'
    def push
      logger.info 'Starting push...'
      refresh
      knife_solo :cook, ssh: true, include_private_key: true
      pull
    end

    desc 'pull', 'Pull down node state and store in local node databag (run automatically after push)'
    def pull
      logger.info 'Starting `pull`!'
      force_deployer unless remote_node.deployment_.user

      raw_json = ssh_run('sudo cat ~deploy/node.json', silent: true)
      # Store the remote_node databag
      data_bag(:nodes)[node.name]  = JSON.load raw_json

      # Now check and see if we are missing the private_key on this node
      private_key = remote_node.private_key || 'default'
      private_key_raw = remote_node.private_key_raw

      if private_key_raw
        # If we don't already have the private_key in our config, let's add it
        unless config.private_keys_[private_key]
          logger.info "Saving new private key `#{private_key}` to config file..."
          config.private_keys![private_key] = private_key_raw
          config.save
        end
      end

    end

    desc 'list', 'Show available nodes in kitchen'
    def list
      inside_kitchen do
        puts Dir.glob('nodes/*.json').sort.map {|n| File.basename(n).sub(/\.json$/, '')}
      end
    end

    desc 'refresh', 'Refresh data bags based on node config. Note this is normally run automatically.'
    long_desc <<-DESC
      Normally, you should not need to run `refresh`. It is run automatically before every `push` or
      `bootstrap`. This command prepares data bags for the node. Presently, this is only used for
      SSH keys. Thus, `refresh` will go through all the `authorized_keys` folders and generate
      data_bags for each user. These data_bags are then used by the Chef Cookbooks during pushes.
    DESC
    def refresh
      logger.info "Starting `refresh`!"
      inside_kitchen do
        # Handle authorized_keys
        logger.debug '# Refreshing authorized_keys'
        Dir.glob('authorized_keys/*') do |user_dir|
          if File.directory? user_dir
            user_name = File.basename(user_dir)
            logger.info "Processing SSH keys for user #{user_name}."
            user_bag = data_bag(:authorized_keys)[user_name]
            user_bag[:keys] = []

            Dir.glob(File.join(user_dir, '*')) do |key_file|
              logger.debug "Reading key file: #{key_file}"
              user_bag[:keys] << File.read(key_file).strip
            end

            logger.info "Writing #{user_bag.options[:filename]}"
            user_bag.save
          else
            logger.info "Ignoring file in authorized_keys (must be inside a directory): #{f}"
          end
        end

        logger.debug '# Ensuring bundle is up to date'
        # Handle bundler, ensure it's up to date
        unless system('bundle check > /dev/null 2>&1')
          logger.info "Bundle out of date! Running bundle update..."
          Cocaine::CommandLine.new('bundle', 'install').run
        end
      end
    end

    desc 'exec "CMD"', 'Execute given command (via SSH) on node, as deploy user (can sudo)'
    def exec(cmd)
      ssh_run(cmd, interactive: true)
    end

    desc 'ssh', 'SSHs to the node as the deploy user (can sudo)'
    def ssh
      exec nil
    end

    desc 'sudo "CMD"', 'Executes the given command as root on the node'
    def sudo(cmd)
      # pull args off of cmd
      exec("sudo #{cmd}")
    end
  end
end