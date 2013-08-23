require_all 'amoeba_deploy_tools/commands'

class AmoebaDeployTools
  class Command
    def initialize(argv)
      argv.push(:help) if argv.empty?

      if self.class.subcommand_classes.include? argv.first.to_sym
        return self.class.subcommand_classes[argv.shift.to_sym].new(argv)
      end

      @subcmd = self.class.subcommand_methods.include?(argv.first.to_sym) ? argv.shift.to_sym : :help
      parse_opts(argv)
      params = method(@subcmd).parameters
      status = params.count > 0 ? send(@subcmd, *@pargs, **@kwargs) : send(@subcmd)
    rescue => e
      STDERR.puts "#{e.class}: #{e.message}", e.bt
      status = 1
    ensure
      exit case (status)
        when Integer  then status
        when false    then 1
        else 0
      end
    end

    def parse_opts(argv)
      @pargs  = []
      @kwargs = {}
      last_flag = nil

      for arg in argv
        if arg =~ /^--?([^=]+)(?:=(.*))?$/
          if last_flag
            @kwargs[last_flag] = true
            last_flag = nil
          end

          if $2
            @kwargs[$1.to_sym] = $2
          else
            last_flag = $1.to_sym
          end
        else
          if last_flag
            @kwargs[last_flag.to_sym] = arg
            last_flag = nil
          else
            @pargs.push(arg)
          end
        end
      end

      @kwargs[last_flag] = true if last_flag
    end

    def self.basecmd
      name.split('::')[2..-1].map {|n| n.downcase}.join(' ')
    end

    def self.cmd
      name.split('::')[-1].downcase.to_sym
    end

    def self.subcommand_classes
      class_subcmds = constants.map {|c| const_get(c)}.select {|c| c < Command }
      Hash[class_subcmds.map {|c| [c.cmd, c]}]
    end

    def self.subcommand_methods
      method_subcmds = instance_methods(false).map {|m| self.instance_method(m)}
      Hash[method_subcmds.map {|c| [c.name, c]}]
    end

    def self.subcommands
      subcommand_methods.merge subcommand_classes
    end

    def help
      STDERR.puts dedent(%{
        Usage: #{self.class.basecmd} <command>

        Possible commands:
      }), indent(self.class.subcommands.keys.join("\n"))

      false
    end
  end

  module Commands
    class Amoeba < Command
      def init(url=nil)
        if Dir.exists('.amoeba')
          STDERR.puts '.amoeba directory already exists'
          return 1
        end

        Dir.mkdir '.amoeba'
        config = ConfigParser.new
        config.kitchen.default.url = url if url 
        config.save(filename: '.amoeba/config')
      end
    end

    class Amoeba::Kitchen < Command
      def add(name='default', url)
      end
    end

    class Amoeba::Node < Command
    end

    class Amoeba::App < Command
    end
  end
end
