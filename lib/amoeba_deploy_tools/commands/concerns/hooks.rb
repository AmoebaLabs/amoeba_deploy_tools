module AmoebaDeployTools
  module Concerns
    module Hooks
      def self.included(base)
        base.extend(ClassMethods)
      end

      module ClassMethods
        ### Class methods
        def before_hooks
          @before_hooks ||= []
        end

        def after_hooks
          @after_hooks ||= []
        end

        def before(&blk)
          @before_hooks ||= []
          @before_hooks << blk
        end

        def after(&blk)
          @after_hooks ||= []
          @after_hooks << blk
        end
      end

      #### Instance methods

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

    end
  end
end