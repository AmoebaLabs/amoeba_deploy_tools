
class AmoebaDeployTools
  class Amoeba < Command
    def init(url=nil)
      if Dir.exists? '.amoeba'
        STDERR.puts '.amoeba directory already exists'
        return 1
      end

      Dir.mkdir '.amoeba'

      config = ConfigParser.new
      config.kitchen!.default!.tap {|k| k.url = url if url }
      config.save(filename: '.amoeba/config', indent: true)

      STDERR.puts 'created .amoeba/config'
    end
  end

  class Amoeba::Kitchen < Command
    def add(name='default', url)
      @config.kitchen!.merge!(name => url)
      @config.save
    end
  end

  class Amoeba::Node < Command
  end

  class Amoeba::App < Command
  end
end
