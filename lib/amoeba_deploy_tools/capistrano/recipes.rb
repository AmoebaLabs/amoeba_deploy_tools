require 'amoeba_deploy_tools/capistrano/common'

Capistrano::Configuration.instance(:must_exist).load do
  _cset(:database_yml_path){ "#{shared_path}/config/database.yml" }

  namespace :amoeba_deploy_tools do
    desc 'Link the shared/config files into the current/config dir.'
    task :symlink_configs, :roles => :app do
      run [ "cd #{latest_release}",
            "ln -nfs #{database_yml_path} config/"
          ].join(' && ')
    end
  end
end