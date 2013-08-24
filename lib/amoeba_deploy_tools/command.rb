
class AmoebaDeployTools
  class Command
    def self.new(*argv)
      argv.unshift(:help) if argv.empty?

      if subcommand_classes.include? argv.first.to_sym
        subcommand_classes[argv.shift.to_sym].new(*argv)
      else
        subcmd = :help
        if subcommand_methods.include? argv.first.to_sym
          subcmd = argv.shift.to_sym
        end

        super(subcmd, argv)
      end
    end

    def initialize(subcmd, argv)
      @subcmd = subcmd
      parse_opts(argv)
      load_config
    end

    def run(do_exit=true)
      self.class.before_hooks.each {|h| instance_eval &h }

      params = method(@subcmd).parameters
      args = [*@pargs].concat(params.flatten.include?(:keyrest) ? [@kwargs] : [])
      status = params.count > 0 ? send(@subcmd, *args) : send(@subcmd)

      self.class.after_hooks.each {|h| instance_eval &h }
    rescue => e
      warn "#{e.class}: #{e.message}", (@kwargs[:debug] ? e.bt : [])
      status = 1
    ensure
      status = case (status)
        when Integer  then status
        when false    then 1
        else 0
      end

      if do_exit
        exit
      else
        return status
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
          if @kwargs[last_flag.to_sym] == Array
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
      @config.tap {|c| c.restore(filename: '.amoeba.yml')}
    end

    def require_kitchen
      return @kitchen if @kitchen

      @kitchen = '.amoeba'
      unless Dir.exists? @kitchen
        raise 'Could not find amoeba kitchen'
      end
    end

    def inside_kitchen
      Dir.chdir(require_kitchen) { yield }
    end

    def require_node
      return @node if @node

      node_name = @argv.shift || @config.node.default
      node_filename = "nodes/#{node_name}.json"
      parse_opts(@argv)

      inside_kitchen do
        if node_name.nil? || !File.exists?(node_filename)
          raise 'Could not find node JSON file.'
        end

        @node = Config.load(node_filename, format: :json)
        @node.tap {|n| n.filename = node_filename } if @node
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

    def help
      warn dedent(%{
        Usage: #{self.class.basecmd} <command>

        Possible commands:
      }), indent(self.class.subcommands.keys.join("\n"))

      false
    end
  end
end
