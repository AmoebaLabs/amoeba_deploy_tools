require "thor"

module AmoebaDeployTools
  class Command < Thor

    option :node, desc: 'name of the node you wish to operate on'

    def initialize(args=[], options={}, config={})
      load_config
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
        self.class.before_hooks.each {|h| instance_eval &h }
        retVal = super
        self.class.after_hooks.each {|h| instance_eval &h }
        return retVal
      end

      def load_config
        @amoebaConfig = Config.new
        @amoebaConfig.tap {|c| c.restore(filename: '.amoeba.yml')}
      end

      def require_kitchen
        return @kitchen if @kitchen

        @kitchen = @config.kitchen.path || nil
        unless Dir.exists? @kitchen
          raise 'Could not find amoeba kitchen'
        else
          @kitchen
        end
      end

      def inside_kitchen
        Dir.chdir(require_kitchen) { yield }
      end

      def require_node
        return @node if @node

        node_name = options[:node]
        node_name = @amoebaConfig.node.default if node_name.nil? && @amoebaConfig.node
        raise 'Error: must specify --node or have a default node in your config file' unless node_name

        node_filename = "nodes/#{node_name}.json"

        inside_kitchen do
          if node_name.nil? || !File.exists?(node_filename)
            raise 'Could not find node JSON file.'
          end

          @node = Config.load(node_filename, format: :json)
          @node.tap {|n| n.filename = node_filename } if @node
        end
      end
    end
  end
end
