require 'json'

module AmoebaDeployTools
  class DataBag
    def new(bag, kitchen)
      @bag_dir = "#{kitchen}/data_bags/#{bag}"
      Dir.mkdir bag_dir unless Dir.exists? bag_dir
    end

    def []=(k, v)
      File.open("#{@bag_dir}/#{k}.json", 'w').write(JSON.dump(v))
    end

    def [](k)
      JSON.load(File.read("#{@bag_dir}/#{k}.json"))
    end
  end
end
