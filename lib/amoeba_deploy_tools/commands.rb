
class AmoebaDeployTools
  class Amoeba < Command
    def init(url=nil)
      if url
        system %W{git clone #{url} .amoeba}
        @config.kitchen!.url = url
      else
        STDERR.puts 'Creating new kitchen in .amoeba'
        Dir.mkdir '.amoeba'
      end

      @config.save
    end

    def sync
    end

    def update
    end

    def config(*args, set: [], get: [])
      require_kitchen

      args.each do |a|
        if a =~ /^(\w[-.\w]*)=(\w+)$/
          @config[$1] = $2
        else
          puts @config[a]
        end
      end

      set.each do |k, v|
        @config[k] = v
      end

      get.each do |k|
        puts @config[k]
      end

      @config.save
    end

    class Node < Command
      def bootstrap
        require_node

        knife_solo :prepare, 'bootstrap-version' => '11.4.2'

        refresh

        knife_solo :cook do
          { run_list: ['role[base]'] }
        end

        pull
      end

      def push
        require_node

        knife_solo :cook

        pull
      end

      def pull
        require_node

        raw_json = `ssh deploy@#{@node.deployment.host} 'sudo cat ~deploy/node.json'`

        DataBag.new(:nodes, @kitchen)[@node.name] = JSON.load raw_json
      end

      def list
        Dir.glob(".amoeba/nodes/*.json").map {|n| File.basename(n)}
      end

      def exec(cmd, *args)
      end

      def shell
      end

      def sudo(cmd, *args)
        exec(:sudo, cmd, *args)
      end

      def knife_solo(cmd, *args)
        if block_given?
        else
          system %W{knife solo --node-name #{@node.name}} + args + [@node.filename]
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
