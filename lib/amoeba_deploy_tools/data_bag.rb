require 'json'

module AmoebaDeployTools
  class DataBag
    def initialize(bag, kitchen)
      @bag_dir = File.join(kitchen, 'data_bags', bag.to_s)
      Dir.mkdir @bag_dir unless Dir.exists? @bag_dir
    end

    def []=(id, item)
      bag_item = DataBagItem.create(item_filename(id), format: :json)
      bag_item.clear.deep_merge!(item.to_hash)
      bag_item.id = id
      bag_item.save
    end

    def [](id)
      DataBagItem.load(item_filename(id), format: :json, create: true).tap do |i|
        i.id = id
      end
    end

    def item_filename(id)
      File.join(@bag_dir, "#{id}.json")
    end
  end

  class DataBagItem < Config
  end
end
