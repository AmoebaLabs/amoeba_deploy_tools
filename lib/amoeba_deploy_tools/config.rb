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

    def [](k)
      chain = k.split('.')
      cur = self

      return super if chain.count < 1

      for c in chain[0..-2]
        if cur and cur.key? c
          cur = cur.regular_reader(c)
        else
          return
        end
      end

      cur[chain[-1]]
    end

    def []=(k, v)
      chain = k.split('.')
      cur = self

      return super if chain.count < 1

      for c in chain[0..-2]
        cur = cur.initializing_reader(c)
      end

      cur[chain[-1]] = v
    end

    def flatten
      flat = {}

      each do |k1, v1|
        if v1.class == self.class
          v1.flatten.each do |k2, v2|
            flat["#{k1}.#{k2}"] = v2
          end
        else
          flat[k1] = v1
        end
      end

      flat
    end

    def to_s
      to_hash.to_s
    end
  end
end
