require_dir './commands'

class AmoebaDeployTools
  class Amoeba < Command
    def init(url=nil)
      if Dir.exists('.amoeba')
        STDERR.puts '.amoeba directory already exists'
        return 1
      end

      Dir.mkdir '.amoeba'
      config = ConfigParser.new
      config.kitchen.default.url = url if url
      config.save(filename: '.amoeba/config')
    end
  end
end
