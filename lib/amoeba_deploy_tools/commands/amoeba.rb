module AmoebaDeployTools

  DEFAULT_SKELETON_REPO = 'https://github.com/AmoebaConsulting/amoeba-kitchen-skel.git'

  class Amoeba < Command

    # Any "global" setup can be done here, as the "amoeba" command will always be initialized
    def initialize(args=[], options={}, config={})
      super
      setup_logger
      setup_cocaine

      # Fix JSON so it doesn't try to dereference json_class in JSON responses
      # See http://blog.defunct.ca/2013/02/01/query-chef-server-api-from-ruby-script/
      JSON.create_id = ''
    end

    desc 'init (url optional)', 'Setup Amoeba Deploy Tools (either by creating a new kitchen or locating an existing one)'
    method_options :skeleton => :boolean
    def init(url=nil)
      # Store the user-specified URL if it exists
      user_url = url if url

      # Check if we're in a git repo
      if system('git rev-parse > /dev/null 2>&1')
        project_dir = %x{git rev-parse --show-toplevel}

        default_kitchen_dir = File.expand_path("#{File.basename(project_dir).chop}-kitchen",
                                       File.expand_path('..', project_dir))
      else
        default_kitchen_dir = File.expand_path('.', 'kitchen')
      end

      kitchen_dir = ask "Where should the new kitchen be located? (default: #{default_kitchen_dir})"
      kitchen_dir = default_kitchen_dir if kitchen_dir.empty?

      if File.exist?(kitchen_dir)
        say 'Existing kitchen found! Will not overwrite.', :yellow
      else
        # Copy (not clone) the repo if the URL isn't specified. If it is, obey the --skeleton param
        copy = url ? options[:skeleton] : true

        # If there was no specified URL, use default one
        url ||= DEFAULT_SKELETON_REPO

        git_opts = copy ?  '--depth 1' : ''
        if system("git clone #{git_opts} #{url} #{kitchen_dir}")
          if copy
            git_dir = File.expand_path('.git', kitchen_dir)
            if File.directory?(git_dir)
              FileUtils.rm_rf(git_dir)
            end
            say_bold "New kitchen created at: #{kitchen_dir}. Please add it to version control"
          else
            say_bold "Kitchen from #{url} has been 'git clone'-ed into your kitchen directory"
          end
        else
          say_fatal "ERROR: Kitchen directory cannot be cloned from URL #{url}"
        end
      end

      # Okay, the kitchen exists (one way or another)

      config.kitchen!.url  = user_url if user_url && !options[:skeleton]
      config.kitchen!.path = kitchen_dir.to_s
      config.save

      say_bold 'Saving ./amoeba.yml config file. We suggest you `git ignore` this (contains local settings).'
    end

    desc 'sync OPTS', 'Not yet implemented.'
    def sync
    end

    desc 'update OPTS', 'Not yet implemented.'
    def update
    end

    desc 'app [COMMAND]', 'Manage the deployed application (see `amoeba app help`)'
    subcommand 'app', AmoebaDeployTools::App

    desc 'node [COMMAND]', 'Deploy and configure nodes (see `amoeba node help`)'
    subcommand 'node', AmoebaDeployTools::Node

    desc 'key [COMMAND]', 'Manage private keys (see `amoeba key help`)'
    subcommand 'key', AmoebaDeployTools::Key

    desc 'ssl [COMMAND]', 'Manage SSL certificates (see `amoeba ssl help`)'
    subcommand 'ssl', AmoebaDeployTools::Ssl

    no_commands do
      def setup_logger
        # Default logging level is warn. You can change this in your .amoeba.yml config
        # by setting `logLevel` or by passing --logLevel option
        level = 'WARN'
        level = config.log_level if config.log_level
        level = options[:'log-level'] if options[:'log-level']
        begin
          level = AmoebaDeployTools::Logger.const_get level.upcase
        rescue NameError
          say "WARNING: Invalid log level: #{level}. Defaulting to WARN.", :red
          level = AmoebaDeployTools::Logger::WARN
        end
        AmoebaDeployTools::Logger.instance.level = level
      end

      def setup_cocaine
        if options[:dry]
          Cocaine::CommandLine.runner = Cocaine::CommandLine::FakeRunner.new
        else
          Cocaine::CommandLine.runner = AmoebaDeployTools::NoiseyCocaineRunner.new
        end

        Cocaine::CommandLine.logger = AmoebaDeployTools::Logger.instance
      end
    end
  end
end
