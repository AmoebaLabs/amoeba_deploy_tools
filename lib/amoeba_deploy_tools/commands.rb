require 'hashie'

class AmoebaDeployTools
  class Amoeba < Command
    def init(url=nil)
      if url
        system %W{git clone #{url} .amoeba}
        @config.kitchen!.url = url
      else
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
      def provision
      end

      def push
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
    end

    class App < Command
      def self.require_node
        node_name = @argv.shift || @config.node.default
        node_filename = ".amoeba/nodes/#{node_name}.json"
        parse_opts(@argv)

        if node_name.nil? || !File.exists?(node_filename)
          raise 'Could not find node JSON file.'
        end

        @node = Hashie::Mash.new(JSON.parse(File.read(node_filename)))
      end

      before {require_node}

      def deploy
        cap :deploy
      end

      def cap(cmd)
      end

      def capfile
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
