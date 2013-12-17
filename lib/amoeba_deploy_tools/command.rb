require 'thor'
require 'hashie/mash'

module AmoebaDeployTools
  class Command < Thor

    option :node, desc: 'name of the node you wish to operate on (set default in .amoeba.yml)'
    option :logLevel, desc: 'log level to output (DEBUG, INFO, WARN (default), or ERROR)'

    # Note that all subcommands will inherit this class. This means any setup done in here
    # will be duplicated if it runs at initialization (since the main command and subcommand are
    # both evaluated at runtime). Thus, it's important not to put anything in the constructor.
    # If you wish to setup any global state, do so in the Amoeba class initializer.
    def initialize(args=[], options={}, config={})
      super
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

    no_commands do
      def invoke_command(command, *args)
        # Ignore hooks on help commands
        if command.name == 'help'
          return super
        end

        self.class.before_hooks.each {|h| instance_eval &h }
        retVal = super
        self.class.after_hooks.each {|h| instance_eval &h }
        return retVal
      end

      def config
        return @amoebaConfig if @amoebaConfig

        @amoebaConfig = Config.new
        @amoebaConfig.tap {|c| c.restore(filename: '.amoeba.yml')}
      end

      def kitchen_path
        return @kitchen if @kitchen

        if config.kitchen_.path
          @kitchen = config.kitchen.path
        else
          @kitchen = '.'
          say 'NOTICE: Using local dir as kitchen path, no `.amoeba.yml` config found. Consider running `amoeba init`'
        end

        say_fatal 'ERROR: Could not find amoeba kitchen' unless Dir.exists? @kitchen

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

      def deployment
        return @deployment if @deployment

        @deployment = Hashie::Mash.new
        @deployment.deep_merge!(node.deployment) if node.deployment

        return @deployment unless node.deployment_.provider

        provider_filename = File.join('data_bags', 'providers', "#{node.deployment.provider}.json")
        remote_node_filename = File.join('data_bags', 'nodes', "#{node.name}.json")

        provider = remote_node = {}
        inside_kitchen do
          provider = Config.load(provider_filename, format: :json)
          remote_node = Config.load(remote_node_filename, format: :json)
        end

        if provider
          @deployment.deep_merge!(provider)
        else
          say_fatal 'ERROR: Provider data bag not found for node.'
        end

        @deployment.deep_merge!(remote_node || {}).deep_merge!(node.deployment)
      end
    end
  end
end
