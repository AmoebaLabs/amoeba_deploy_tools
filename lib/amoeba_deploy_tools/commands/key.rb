module AmoebaDeployTools
  class Key < Command

    desc 'create', 'Create a private_key (used to encrypt secret data_bags like SSL certs)'
    def create(name=nil)
      validate_chef_id!(name)

      inside_kitchen do
        key = Cocaine::CommandLine.new('openssl', "rand -base64 512 | tr -d '\\r\\n'",
                                       runner: Cocaine::CommandLine::BackticksRunner.new).run

        unless File.directory?('private_keys')
          logger.warn 'Creating private_key directory in kitchen (does not exist!).'
          FileUtils.mkdir_p('private_keys')
          FileUtils.touch(File.join('private_keys', '.gitkeep'))

          unless File.open('.gitignore').lines.any? { |line| line.chomp =~ /private_keys/ }
            File.open('.gitignore', 'a') do |f|
              f.write "\n"
              f.puts '# For security, ignore private keys (used to encrypt things like certs)'
              f.puts 'private_keys/*.key'
              f.write "\n"
            end
          end

        end

        filename = File.join("private_keys", "#{name}.key")

        logger.debug "Writing key to file: #{filename}"

        File.open(filename, 'w') do |file|
          file.write(key)
        end

      end
    end

  end
end