require 'json'

module AmoebaDeployTools
  class Node < Command
    include AmoebaDeployTools::Concerns::SSH

    desc 'bootstrap', 'Setup the node initially (run the first time you want to deploy a node)'
    long_desc <<-LONGDESC
      `bootstrap` will load Chef and the `basenode` recipe on the node. This is effectively the way
      to setup a node initially. Subsequent runs can use the `node push` command.
    LONGDESC
    def bootstrap
      logger.info 'Starting `bootstrap`!'

      refresh
      knife_solo :prepare, 'bootstrap-version' => '11.4.2'

      knife_solo :cook do |j|
        j.run_list = ['role[base]']
      end

      pull

      logger.warn 'Node bootstrapped successfully, you can now push to the node:'
      logger.warn "\tamoeba node push --node #{options[:node]}\n"
    end

    desc 'push', 'Push any changes to the node'
    def push
      knife_solo :cook
      pull
    end

    desc 'pull', 'Pull down node state and store in local node databag (run automatically after push)'
    def pull
      logger.info 'Starting `pull`!'

      raw_json = ssh_run('sudo cat ~deploy/node.json', silent: true)

      data_bag(:nodes)[node.name] = JSON.load raw_json
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