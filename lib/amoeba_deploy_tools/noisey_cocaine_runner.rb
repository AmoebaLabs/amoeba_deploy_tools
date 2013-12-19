# coding: UTF-8
require 'pty'

module AmoebaDeployTools
  class NoiseyCocaineRunner
    def self.supported?
      true
    end

    def supported?
      self.class.supported?
    end

    def call(command, env = {})
      buffer = ''
      with_modified_environment(env) do
        begin
          # Use PTY.spawn so we don't buffer anything. r will contain the output (stdout & stderr)
          PTY.spawn(command) do |r,w,pid|
            begin
              r.each { |line| Cocaine::CommandLine.logger.debug line.strip; buffer << line }
            rescue Errno::EIO
              # Output is done
            end
            # Note: This requires ruby 1.9.2!
            Process.wait(pid) # Wait for the process to die (so $? is set)
          end
        rescue PTY::ChildExited
          # The command is done
          # $!.status.exitstatus would likely contain the exit code
        end
      end
      buffer
    end

    private

    def with_modified_environment(env, &block)
      ClimateControl.modify(env, &block)
    end
  end
end
