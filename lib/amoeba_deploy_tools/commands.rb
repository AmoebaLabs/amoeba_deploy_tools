
class AmoebaDeployTools
  class Amoeba < Command
    def init(url=nil)
      if Dir.exists? '.amoeba'
        STDERR.puts '.amoeba directory already exists'
        return 1
      end

      if url
        system %W{git clone #{url} .amoeba}
      else
        Dir.mkdir '.amoeba'
      end

      @config.kitchen!.default!.tap {|k| k.url = url if url }
      @config.save

      STDERR.puts 'created .amoeba/config'
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
      def init
      end

      def deploy
        cap :deploy
      end

      def cap(cmd)
      end

      def capfile
      end

      def exec
      end

      def shell
      end
    end
  end
end
