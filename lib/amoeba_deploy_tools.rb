require 'amoeba_deploy_tools/config_parser'
require 'amoeba_deploy_tools/helpers'

class AmoebaDeployTools
  module Commands
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

    def refresh
    end

    def provision(node)
    end

    def deploy(node)
    end

    def update(node)
    end

    def cleanup(node)
    end

    def exec(node)
    end

    def shell(node)
    end

    def help(*a, **kw)
      puts dedent %{
        Usage: amoeba <command>

        Possible commands:
      }
      puts indent Commands.instance_methods.join("\n")

      1
    end
  end

  include Commands

  def initialize(command=:help, *args, **kwargs)
    params = method(command).parameters
    status = params.count > 0 ? send(command, *args, **kwargs) : send(command)
    exit status || 0
  rescue ArgumentError => e
    STDERR.puts e
    exit 1
  end

  def self.run(args)
    unless command = args.shift and Commands.instance_methods(false).include? command
      command = :help
    end

    pargs, kwargs = parse_opts(args)
    new(command, *pargs, **kwargs)
  end

  def self.parse_opts(args)
    pargs  = []
    kwargs = {}
    last_flag = nil

    for arg in args
      if arg =~ /^--?([^=]+)$/
        if last_flag
          kwargs[last_flag] = true
          last_flag = nil
        end

        last_flag = $1.to_sym
      elsif arg =~ /^--?([^=]+)=(.*)$/
        if last_flag
          kwargs[last_flag] = true
          last_flag = nil
        end

        kwargs[$1.to_sym] = $2
      else
        if last_flag
          kwargs[last_flag.to_sym] = arg
          last_flag = nil
        else
          pargs.push(arg)
        end
      end
    end

    if last_flag
      kwargs[last_flag] = true
      last_flag = nil
    end

    [pargs, kwargs]
  end
end
