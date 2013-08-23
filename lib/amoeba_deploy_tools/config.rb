require 'yaml'
require 'hashie/mash'

class AmoebaDeployTools
  class Config < Hashie::Mash
    def self.load(filename, **opts)
      new.tap {|c| c.options(filename: filename, **opts) }.restore
    end

    def options(**opts)
      @opts ||= {}
      @opts.merge! opts
    end

    def restore(**opts)
      options(opts)

      filename = options[:filename]
      return unless filename

      File.open(filename) do |fh|
        self.clear.deep_merge! YAML.load(fh.read)
      end

      self
    end

    def save(**opts)
      options(opts)

      filename = options[:filename]
      return unless filename

      File.open(filename) do |fh|
        fh.write(YAML.dump(self.to_hash))
      end

      self
    end

    def to_s
      to_hash.to_s
    end
  end
end
