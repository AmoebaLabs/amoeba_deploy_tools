require 'optparse'

module AmoebaDeployTools
  module Commands
    def init(url)
      if Dir.exists('.amoeba')
        STDERR.puts ".amoeba directory already exists"
        return 1
      end

      system "git clone #{url} .amoeba"

      File.new(cfg, 'w') unless File.exists? cfg='.amoeba/config'
    end

    def refresh
    end

    def provision(*node)
    end

    def deploy(*node)
    end

    def update(*node)
    end

    def cleanup(*node)
    end

    def exec(*node)
    end

    def shell(*node)
    end
  end

  module Runner
    def self.run(args)
      unless command = args.shift and instance_methods(false).include? command
        command = :help
      end

      new(args).send(command)
    end

    protected

    def initialize(args)
      @ARGV = args
    end

    def options(opt_hash)
      OptionParser.new do |opts|
        opts.banner = "Usage: amoeba <command> [<args>]"

        opt_hash.map do |o, d|
          opts.on *d { |v| self.instance_variable_set(o, v) }
        end
      end.parse @ARGV
    end
  end
end
