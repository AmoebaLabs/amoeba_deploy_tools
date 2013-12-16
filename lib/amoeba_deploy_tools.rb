require 'amoeba_deploy_tools/version'
require 'amoeba_deploy_tools/helpers'
require 'amoeba_deploy_tools/config'
require 'amoeba_deploy_tools/command'
require 'amoeba_deploy_tools/data_bag'
require 'amoeba_deploy_tools/noisey_cocaine_runner'
require 'amoeba_deploy_tools/logger'

require 'amoeba_deploy_tools/commands/app'
require 'amoeba_deploy_tools/commands/node'
require 'amoeba_deploy_tools/commands/amoeba'

require 'cocaine'
Cocaine::CommandLine.runner = AmoebaDeployTools::NoiseyCocaineRunner.new
Cocaine::CommandLine.logger = AmoebaDeployTools::Logger.instance
