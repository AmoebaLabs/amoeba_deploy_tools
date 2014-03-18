# Adds sidekiq tasks to capistrano. But they aren't going to be called by default in your deploy
# process. If you use capistrano, add the following to your deploy.rb (or something included by it):
#
#  after "deploy:stop",    "sidekiq:stop"
#  after "deploy:start",   "sidekiq:start"
#  before "deploy:restart", "sidekiq:restart"

Capistrano::Configuration.instance.load do
  namespace :sidekiq do
    desc "Start sidekiq"
    task :start, roles: :web do
      sidekiq_processes.times do |i|
        run "#{shared_path}/init/start_sidekiq #{i}"
      end
    end

    desc "Stop sidekiq"
    task :stop, roles: :web do
      sidekiq_processes.times do |i|
        run "#{shared_path}/init/stop_sidekiq #{i}"
      end
    end

    desc "Restart sidekiq"
    task :restart, roles: :web do
      stop
      start
    end
  end
end


