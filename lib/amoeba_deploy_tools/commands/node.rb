require 'json'

module AmoebaDeployTools
  class Node < Command

    desc 'bootstrap', 'Setup the node initially (run the first time you want to deploy a node)'
    long_desc <<-LONGDESC
      `bootstrap` will load Chef and the `basenode` recipe on the node. This is effectively the way
      to setup a node initially. Subsequent runs can use the `node push` command.
    LONGDESC
    def bootstrap
      knife_solo :prepare, 'bootstrap-version' => '11.4.2'
      #
      #refresh
      #
      #knife_solo :cook do
      #  { run_list: ['role[base]'] }
      #end
      #
      #pull
    end

    desc 'push', 'Push any changes to the node'
    def push
      knife_solo :cook
      pull
    end

    desc 'pull', 'Pull down node state and store in local node databag (run automatically after push)'
    def pull
      raw_json = `ssh deploy@#{node.deployment.host} 'sudo cat ~deploy/node.json'`

      DataBag.new(:nodes, @kitchen)[node.name] = JSON.load raw_json
    end

    desc 'list', 'Show available nodes in kitchen'
    def list
      inside_kitchen do
        puts Dir.glob('nodes/*.json').sort.map {|n| File.basename(n).sub(/\.json$/, '')}
      end
    end

    desc 'exec', 'Execute given command (via SSH) on node, as deploy user (has sudo)'
    def exec(cmd, *args)
      system :ssh, node_cmd(port: '-p', ident: '-i'), *args, (cmd ? "'#{cmd}'" : '');
    end

    desc 'ssh', 'SSHs to the node as the deploy user (can sudo)'
    def ssh
      exec nil
    end

    desc 'sudo "CMD"', 'Executes the given command as root on the node'
    def sudo(cmd)
      # pull args off of cmd
      exec(:sudo, cmd, *args)
    end

    no_commands do
      # Outputs SSH options for connecting to this node (provide a map of deploy key to command
      # line arg name).
      def node_host_args(flag_map)
        say_fatal 'ERROR: Missing deployment info for node.' unless deployment && deployment.host

        host_arg = deployment.host
        host_arg = "#{deployment.user}@#{host_arg}" if deployment.user

        # Iterate through all the specified flags and check if they're defined in the deployment
        # config, appending them to the output if they are.
        flag_map.each do |field, argument_name|
          host_arg << " #{argument_name} #{deployment[field]}" if deployment[field]
        end

        host_arg
      end

      def knife_solo(cmd, options={})
        say_fatal 'ERROR: Node must have a name defined' unless node.name

        exec = "bundle exec knife solo #{cmd.to_s} "
        exec << node_host_args(port: '--ssh-port',
                               config: '--ssh-config-file',
                               ident: '--identity-file') << ' '
        exec << "--node-name #{node.name}"

        # Now go through all the options specified and append them to args
        # Only, json is a special argument that causes some different behavior
        json = options.delete(:json).to_json if options[:json]
        args = ''
        options.each do |argument, value|
          args << " --#{argument} #{value}"
        end


        inside_kitchen do
          # JSON will be written to a temp file and used in place of the node JSON file
          if json
            with_tmpfile(json) do |file_name|
              knife_solo_cmd = Cocaine::CommandLine.new(exec, "#{args} #{file_name}")
              knife_solo_cmd.run
            end
          else
            knife_solo_cmd = Cocaine::CommandLine.new(exec, "#{args} #{node.filename}")
            knife_solo_cmd.run
            #exec << args << " #{node.filename}"
            #puts "Exec: #{exec}."
            #system exec
          end
        end
      end
    end
  end
end