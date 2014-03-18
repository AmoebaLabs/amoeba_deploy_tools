require 'capistrano/version'

if defined?(Capistrano::VERSION) && Capistrano::VERSION >= '3.0'
  raise 'We do not yet support Capistrano v3.0. Please downgrade, send us a pull request, or symlink database.yml yourself.'
else
  require 'amoeba_deploy_tools/capistrano/recipes'

  Capistrano::Configuration.instance(:must_exist).load do
    after   'deploy:finalize_update',  'amoeba:symlink_configs'
  end
end