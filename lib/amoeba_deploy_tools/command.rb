require 'thor'
require 'hashie/mash'

module AmoebaDeployTools
  class Command < Thor

    include AmoebaDeployTools::Concerns::Hooks

    option :node, desc: 'name of the node you wish to operate on (set default in .amoeba.yml)'
    option :'log-level', desc: 'log level to output (DEBUG, INFO, WARN (default), or ERROR)'
    option :dry, type: :boolean, default: false, desc: 'Don\'t actually execute any chef commands (just show what would be run)'

    # Note that all subcommands will inherit this class. This means any setup done in here
    # will be duplicated if it runs at initialization (since the main command and subcommand are
    # both evaluated at runtime). Thus, it's important not to put anything in the constructor.
    # If you wish to setup any global state, do so in the Amoeba class initializer.
    def initialize(args=[], options={}, config={})
      super
    end

    no_commands do
      def config
        return @amoebaConfig if @amoebaConfig

        @amoebaConfig = Config.load('.amoeba.yml')
      end

      def kitchen_path
        return @kitchen if @kitchen

        if config.kitchen_.path
          @kitchen = config.kitchen.path
        else
          @kitchen = '.'
          logger.warn 'Using local dir as kitchen path, no `.amoeba.yml` config found. Consider running `amoeba init`'
        end

        say_fatal "ERROR: Could not find amoeba kitchen: #{@kitchen}" unless Dir.exists? @kitchen

        @kitchen
      end

      def inside_kitchen(&block)
        if defined?(Bundler)
          Bundler.with_clean_env do
            Dir.chdir(kitchen_path) { block.call }
          end
        else
          Dir.chdir(kitchen_path) { block.call }
        end
      end

      # The node must be specified unless you set a default one. You can specify it with the
      # `--node [name]` option, or by setting `[:node][:default]` in your `.amoeba.yml``
      def node
        return @node if @node

        node_name = options[:node] || config.node_.default_
        say_fatal 'ERROR: must specify --node or have a default node in your config file' unless node_name

        inside_kitchen do
          node_filename = File.expand_path(File.join('nodes', "#{node_name}.json"))
          if node_name.nil? || !File.exists?(node_filename)
            say_fatal "ERROR: Could not find node JSON file: #{node_filename}"
          end

          @node = Config.load(node_filename, format: :json)
          @node.tap {|n| n.filename = node_filename } if @node
        end
      end

      def remote_node
        data_bag(:nodes)[node.name]
      end

      def data_bag(name)
        DataBag.new(name, kitchen_path)
      end

      def deployment
        @deployment = Hashie::Mash.new
        @deployment.deep_merge!(node.deployment) if node.deployment

        provider = data_bag(:providers)[node.deployment.provider] if node.deployment_.provider
        @deployment.deep_merge!(provider) if provider

        # Remove ident if we have a remote node, as host keys should be managed by us
        @deployment.delete('ident') if remote_node.deployment

        @deployment.deep_merge!(remote_node.deployment) if remote_node.deployment
        @deployment.deep_merge!(node.deployment)

        return @deployment
      end

      def logger
        Logger.instance
      end

      def validate_chef_id!(name)
        say_fatal "You must specify a key name for your data bag id." unless name
        unless name =~ /^[a-zA-Z0-9\_\-]+$/
          say_fatal "Your data bag name must only contain alphanums, dashes, and underscores. `#{name}` is invalid!"
        end
        return true
      end

    end
  end
end
