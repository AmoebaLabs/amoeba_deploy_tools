module AmoebaDeployTools
  class App < Command
    before {require_node}

    desc 'deploy', 'Deploy the application (using capistrano)'
    def deploy
      cap :deploy
    end

    desc 'capfile', 'Generate Capfile for application'
    def capfile
      require_node

      app = @node.application
      sudo(@node.name, "cat ~#{app.name}/shared/config/Capfile")
    end

    desc 'exec CMD', "executes CMD on remote server in app's env"
    def exec
    end

    desc 'ssh', 'SSHs to the application node, as the application user'
    def ssh
    end

    no_commands do
      def cap(cmd)
      end
    end
  end
end