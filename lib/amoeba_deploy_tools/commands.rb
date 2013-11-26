require 'highline/import'

module AmoebaDeployTools

  DEFAULT_SKELETON_REPO = 'https://github.com/AmoebaConsulting/amoeba-kitchen-skel.git'

  class Amoeba < Command
    def init(url=nil)
      # Store the user-specified URL if it exists
      user_url = url if url

      # Check if we're in a git repo
      if system('git rev-parse')
        project_dir = %x{git rev-parse --show-toplevel}

        kitchen_dir = File.expand_path("#{File.basename(project_dir).chop}-kitchen",
                                    File.expand_path("..", project_dir))
      else
        kitchen_dir = File.expand_path("kitchen", ".")
      end

      kitchen_dir = ask("Where should the new kitchen be located? (enter to accept default)") { |q| q.default = kitchen_dir }

      if File.exist?(kitchen_dir)
        STDERR.puts "Existing kitchen found! Will not overwrite."
      else
        # Copy (not clone) the repo if the URL isn't specified. If it is, obey the --skeleton param
        copy = url ? @kwargs[:skeleton] : true

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
          raise "ERROR: Kitchen directory cannot be cloned from URL #{url}"
        end
      end

      # Okay, the kitchen exists (one way or another)

      @config.kitchen!.url  = user_url if user_url
      @config.kitchen!.path = kitchen_dir.to_s
      @config.save

      say_bold "Saving ./amoeba.yml config file. We suggest you git ignore this."
    end

    def sync
    end

    def update
    end

    def config(val=nil, set: nil, get: nil)
      require_kitchen

      if key = set and val
        @config[key] = val
        @config.save
      elsif key = get || val
        puts @config[key]
      else
        puts @config.flatten.map {|k,v| "#{k}=#{v}"}
      end
    end

    class Node < Command
      def bootstrap
        knife_solo :prepare, 'bootstrap-version' => '11.4.2'

        refresh

        knife_solo :cook do
          { run_list: ['role[base]'] }
        end

        pull
      end

      def push
        knife_solo :cook

        pull
      end

      def pull
        require_node

        raw_json = `ssh deploy@#{@node.deployment.host} 'sudo cat ~deploy/node.json'`

        DataBag.new(:nodes, @kitchen)[@node.name] = JSON.load raw_json
      end

      def list
        inside_kitchen do
          puts Dir.glob('nodes/*.json').sort.map {|n| File.basename(n).sub(/\.json$/, '')}
        end
      end

      def exec(cmd, *args)
        require_node

        system :ssh, node_cmd(port: '-p', ident: '-i'), *args, (cmd ? "'#{cmd}'" : '');
      end

      def shell
        exec nil
      end

      def sudo(cmd, *args)
        exec(:sudo, cmd, *args)
      end

      def knife_solo(cmd, *args)
        require_node

        inside_kitchen do
          knife_solo_cmd = %W{knife solo --node-name #{@node.name}} + args
          if block_given?
            with_tmpfile JSON.dump(yield) {|f| system *knife_solo_cmd, f }
          else
            system *knife_solo_cmd, @node.filename
          end
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
