
class AmoebaDeployTools
  class Amoeba < Command
    def init(url=nil)
      if url || (@config && url = @config.kitchen!.url)
        %x{git clone #{url} .amoeba}
        @config.kitchen!.url = url
        @config.save
      else
        STDERR.puts 'Creating new kitchen in .amoeba'
        Dir.mkdir '.amoeba'
      end
    end

    def sync
    end

    def update
    end

    def config(val=nil, set: nil, get: nil)
      require_kitchen

      if key = set and val
        @config[key] = val
        @config.save
      elsif key = get || val
        puts @config[key]
      else
        puts @config.flatten.map {|k,v| "#{k}=#{v}"}
      end
    end

    class Node < Command
      def bootstrap
        knife_solo :prepare, 'bootstrap-version' => '11.4.2'

        refresh

        knife_solo :cook do
          { run_list: ['role[base]'] }
        end

        pull
      end

      def push
        knife_solo :cook

        pull
      end

      def pull
        require_node

        raw_json = `ssh deploy@#{@node.deployment.host} 'sudo cat ~deploy/node.json'`

        DataBag.new(:nodes, @kitchen)[@node.name] = JSON.load raw_json
      end

      def list
        puts Dir.glob(".amoeba/nodes/*.json").map {|n| File.basename(n).sub(/\.json$/, '')}
      end

      def exec(cmd, *args)
        require_node

        system :ssh, node_cmd(port: '-p', ident: '-i'), *args, (cmd ? "'#{cmd}'" : '');
      end

      def shell
        exec nil
      end

      def sudo(cmd, *args)
        exec(:sudo, cmd, *args)
      end

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

    class App < Command
      before {require_node}

      def deploy
        cap :deploy
      end

      def cap(cmd)
      end

      def capfile
        require_node

        app = @node.application
        sudo(@node.name, "cat ~#{app.name}/shared/config/Capfile")
      end

      def exec
      end

      def shell
      end
    end
  end
end
