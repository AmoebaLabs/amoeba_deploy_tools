module AmoebaDeployTools
  module Concerns
    module SSH
      def self.included(base)
        base.extend(ClassMethods)
      end

      module ClassMethods
        ### Class methods
      end

      ### Instance methods

      # Outputs SSH options for connecting to this node (provide a map of deploy key to command
      # line arg name).
      def node_host_args(flag_map)
        say_fatal 'ERROR: Missing deployment info for node.' unless deployment && deployment.host

        host_arg = deployment.host
        host_arg = "#{deployment.user}@#{host_arg}" if deployment.user

        # Iterate through all the specified flags and check if they're defined in the deployment
        # config, appending them to the output if they are.
        flag_map.each do |field, argument_name|
          host_arg << " #{argument_name} #{deployment[field]}" if deployment[field]
        end

        host_arg
      end

      # Run knife solo command on server
      def knife_solo(cmd, options={})
        say_fatal 'ERROR: Node must have a name defined' unless node.name

        # Ensure json is a hashie
        json = options.delete(:json) || Hashie::Mash.new

        # If a block is specified, it means we have json in it, so let's resolve it
        yield(json) if block_given?

        # Ensure JSON for the node is set. It is either provided by the calling party, or we use the
        # node file's definitions.
        if json.empty?
          json.deep_merge!(node)
        end

        exec = "bundle exec knife solo #{cmd.to_s} "

        if options.delete(:ssh)
          exec << node_host_args(port: '--ssh-port',
                                 config: '--ssh-config-file',
                                 ident: '--identity-file') << ' '
          exec << "--no-host-key-verify --node-name #{node.name}"
        end

        if options.delete(:include_private_key)
          private_key = node.private_key || 'default'
          private_key = config.private_keys_[private_key]

          # Stick the private key into a our custom JSON (to be appended to the node)
          json.private_key_raw = private_key if private_key
        end

        opts = {}
        opts[:runner] = AmoebaDeployTools::InteractiveCocaineRunner.new if options.delete(:interactive)

        # Now go through all the options specified and append them to args
        args = ''
        options.each do |argument, value|
          args << " --#{argument} #{value}"
        end

        inside_kitchen do
          # JSON will be written to a temp file and used in place of the node JSON file
          with_tmpfile(JSON.dump(json), name: ['node', '.json']) do |file_name|
            knife_solo_cmd = Cocaine::CommandLine.new(exec, "#{args} #{file_name}", opts)
            knife_solo_cmd.run
          end
        end
      end

      def ssh_run(cmd, options)
        options = {
          silent: false,
          interactive: false
        }.merge!(options)

        opts = {}
        opts[:runner] = Cocaine::CommandLine::BackticksRunner.new if options[:silent]
        opts[:runner] = AmoebaDeployTools::InteractiveCocaineRunner.new if options[:interactive]

        ssh_cmd = node_host_args(port: '-p', ident: '-i')

        [ 'Compression=yes',
          'DSAAuthentication=yes',
          'LogLevel=FATAL',
          'StrictHostKeyChecking=no',
          'UserKnownHostsFile=/dev/null'
        ].each do |opt|
          ssh_cmd << " -o #{opt}"
        end

        ssh_cmd << " '#{cmd}'" if cmd && !cmd.empty?

        Cocaine::CommandLine.new('ssh', ssh_cmd, opts).run
      end
    end
  end
end