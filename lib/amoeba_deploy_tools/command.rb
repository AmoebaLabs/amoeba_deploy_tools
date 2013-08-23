
class AmoebaDeployTools
  class Command
    def initialize(argv)
      argv.push(:help) if argv.empty?

      if self.class.subcommand_classes.include? argv.first.to_sym
        return self.class.subcommand_classes[argv.shift.to_sym].new(argv)
      end

      @subcmd = self.class.subcommand_methods.include?(argv.first.to_sym) ? argv.shift.to_sym : :help
      parse_opts(argv)
      load_config

      self.class.before_hooks.each {|h| instance_eval &h }
      params = method(@subcmd).parameters
      args = [*@pargs].concat(params.flatten.include?(:keyrest) ? [@kwargs] : [])
      status = params.count > 0 ? send(@subcmd, *args) : send(@subcmd)
      self.class.after_hooks.each {|h| instance_eval &h }
    rescue => e
      STDERR.puts "#{e.class}: #{e.message}", (@kwargs[:debug] ? e.bt : [])
      status = 1
    ensure
      exit case (status)
        when Integer  then status
        when false    then 1
        else 0
      end
    end

    def parse_opts(argv)
      @argv   = argv
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
            if @kwargs[$1.to_sym] == Array
              @kwargs[$1.to_sym] << $2
            else
              @kwargs[$1.to_sym] = $2
            end
          else
            last_flag = $1.to_sym
          end
        elsif last_flag
          if @kwargs[$1.to_sym] == Array
            @kwargs[last_flag.to_sym] << arg
          else
            @kwargs[last_flag.to_sym] = arg
          end

          last_flag = nil
        else
          @pargs.push(arg)
        end
      end

      @kwargs[last_flag] = true if last_flag
    end

    def load_config
      @config = Config.new
      @config.options(filename: '.amoeba.yml')
      @config.restore || @config
    end

    def require_kitchen
      unless Dir.exists? '.amoeba'
        raise 'Missing kitchen' and exit 1
      end
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

    def self.before_hooks
      @before_hooks ||= []
    end

    def self.after_hooks
      @after_hooks ||= []
    end

    def self.before(&blk)
      @before_hooks ||= []
      @before_hooks << blk
    end

    def self.after(&blk)
      @after_hooks ||= []
      @after_hooks << blk
    end
  end
end
