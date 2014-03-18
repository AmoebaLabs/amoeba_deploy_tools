require 'amoeba_deploy_tools/capistrano/common'
require 'amoeba_deploy_tools/capistrano/sidekiq'

Capistrano::Configuration.instance(:must_exist).load do
  _cset(:database_yml_path){ "#{shared_path}/config/database.yml" }

  namespace :amoeba do
    desc 'Link the shared/config files into the current/config dir.'
    task :symlink_configs, :roles => :app do
      run [ "cd #{latest_release}",
            "ln -nfs #{database_yml_path} config/"
          ].join(' && ')
    end

    desc "create the database (and load seed data)"
    task :db_setup do
      run "cd #{current_path}; bundle exec rake db:setup RAILS_ENV=#{rails_env}"
    end

    desc <<-DESC
    Deploys and starts a `cold' application. This is useful if you have not \
    deployed your application before, or if your application is (for some \
    other reason) not currently running. It will deploy the code, create and seed the DB, run any \
    pending migrations, and then instead of invoking `deploy:restart', it will \
    invoke `deploy:start' to fire up the application servers.
    DESC
    task :bootstrap do
      deploy.update
      amoeba.db_setup
      deploy.migrate
      deploy.start
    end
  end

  namespace :deploy do
    desc "restart the application (trigger passenger restart)"
    task :restart, :roles => :app, :except => { :no_release => true } do
      run "touch #{current_path}/tmp/restart.txt"
    end
  end

end