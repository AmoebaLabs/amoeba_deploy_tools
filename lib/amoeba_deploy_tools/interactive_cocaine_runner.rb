# coding: UTF-8
module AmoebaDeployTools
  class InteractiveCocaineRunner
    def self.supported?
      true
    end

    def supported?
      self.class.supported?
    end

    def call(command, env = {})
      with_modified_environment(env) do
        system(command)
      end
      ''
    end

    private

    def with_modified_environment(env, &block)
      ClimateControl.modify(env, &block)
    end
  end
end
