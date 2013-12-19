require 'thor'
require 'hashie/mash'

module AmoebaDeployTools
  class Command < Thor

    include AmoebaDeployTools::Concerns::Hooks

    option :node, desc: 'name of the node you wish to operate on (set default in .amoeba.yml)'
    option :logLevel, desc: 'log level to output (DEBUG, INFO, WARN (default), or ERROR)'
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
        Bundler.with_clean_env do
          Dir.chdir(kitchen_path) { block.call }
        end
      end

      def node
        return @node if @node

        node_name = options[:node] || config.node_.default
        say_fatal 'ERROR: must specify --node or have a default node in your config file' unless node_name

        node_filename = File.join('nodes', "#{node_name}.json")

        inside_kitchen do
          if node_name.nil? || !File.exists?(node_filename)
            say_fatal 'ERROR: Could not find node JSON file.'
          end

          @node = Config.load(node_filename, format: :json)
          @node.tap {|n| n.filename = node_filename } if @node
        end
      end

      def data_bag(name)
        DataBag.new(name, kitchen_path)
      end

      def deployment
        return @deployment if @deployment

        @deployment = Hashie::Mash.new
        @deployment.deep_merge!(node.deployment) if node.deployment

        return @deployment unless node.deployment_.provider

        provider = data_bag(:providers)[node.deployment.provider]
        remote_node = data_bag(:nodes)[node.name]

        @deployment.deep_merge!(provider).deep_merge!(remote_node).deep_merge!(node.deployment)
      end

      def logger
        Logger.instance
      end
    end
  end
end
