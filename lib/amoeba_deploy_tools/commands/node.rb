module AmoebaDeployTools
  class Node < Command

    desc 'bootstrap', 'Setup the node initially (run the first time you want to deploy a node)'
    long_desc <<-LONGDESC
      `bootstrap` will load Chef and the `basenode` recipe on the node. This is effectively the way
      to setup a node initially. Subsequent runs can use the `node push` command.
    LONGDESC
    def bootstrap
      knife_solo :prepare, 'bootstrap-version' => '11.4.2'

      refresh

      knife_solo :cook do
        { run_list: ['role[base]'] }
      end

      pull
    end

    desc 'push', 'Push any changes to the node'
    def push
      knife_solo :cook
      pull
    end

    desc 'pull', 'Pull down node state and store in local node databag (run automatically after push)'
    def pull
      require_node

      raw_json = `ssh deploy@#{@node.deployment.host} 'sudo cat ~deploy/node.json'`

      DataBag.new(:nodes, @kitchen)[@node.name] = JSON.load raw_json
    end

    desc 'list', 'Show available nodes in kitchen'
    def list
      inside_kitchen do
        puts Dir.glob('nodes/*.json').sort.map {|n| File.basename(n).sub(/\.json$/, '')}
      end
    end

    desc 'exec', 'Execute given command (via SSH) on node, as deploy user (has sudo)'
    def exec(cmd, *args)
      require_node

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
      def knife_solo(cmd, *args)
        require_node

        inside_kitchen do
          knife_solo_cmd = %W{knife solo --node-name #{@node.name}} + args
          if block_given?
            with_tmpfile JSON.dump(yield) {|f| system *knife_solo_cmd, f }
          else
            system *knife_solo_cmd, @node.filename
          end
        end
      end
    end
  end
end