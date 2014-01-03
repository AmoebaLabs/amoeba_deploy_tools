module AmoebaDeployTools
  class Key < Command

    desc 'create', 'Create a private_key (used to encrypt secret data_bags like SSL certs)'
    def create(name=nil)
      validate_chef_id!(name)

      key = Cocaine::CommandLine.new('openssl', "rand -base64 512 | tr -d '\\r\\n'",
                                     runner: Cocaine::CommandLine::BackticksRunner.new).run
      config.private_keys![name] = key

      logger.debug "Saving key to `.amoeba.yml` config"

      if config.new_file?
        say_fatal "Cannot create new key, no .amoeba.yml file found! Please run `amoeba init`"
      end

      config.save
    end

  end
end