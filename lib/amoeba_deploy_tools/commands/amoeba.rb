module AmoebaDeployTools

  DEFAULT_SKELETON_REPO = 'https://github.com/AmoebaConsulting/amoeba-kitchen-skel.git'

  class Amoeba < Command
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

      @amoebaConfig.kitchen!.url  = user_url if user_url && !options[:skeleton]
      @amoebaConfig.kitchen!.path = kitchen_dir.to_s
      @amoebaConfig.save

      say_bold 'Saving ./amoeba.yml config file. We suggest you `git ignore` this (contains local settings).'
    end

    desc 'sync OPTS', 'Not yet implemented.'
    def sync
    end

    desc 'update OPTS', 'Not yet implemented.'
    def update
    end

    desc "app [COMMAND]", "Manage the deployed application (see `amoeba help app`)"
    subcommand "app", AmoebaDeployTools::App

  end
end
