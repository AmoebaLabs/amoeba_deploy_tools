require 'yaml'
require 'json'
require 'fileutils'
require 'hashie/mash'

module AmoebaDeployTools
  class Config < Hashie::Mash
    def self.load(filename, **opts)
      Config.new.tap do |c|
        c.options(filename: filename, **opts)
        c.restore
      end
    end

    def self.create(filename, **opts)
      Config.new.tap do |c|
        c.options(filename: filename, create: true, **opts)
      end
    end

    def options(**opts)
      @opts ||= { format: :yaml }
      @opts.merge! opts
    end

    def restore(**opts)
      options(opts)

      return unless filename = options[:filename]

      self.clear.deep_merge! deserialize(File.read(filename))

      self
    rescue Errno::ENOENT
      FileUtils.touch(filename) and retry if options[:create]
    end

    def save(**opts)
      options(opts)

      return unless filename = options[:filename]

      File.open(filename, 'w') do |fh|
        fh.write(serialize(self.to_hash))
      end

      self
    rescue Errno::ENOENT
      FileUtils.touch(filename) and retry if options[:create]
    end

    def [](k)
      chain = k.to_s.split('.')
      cur = self

      return super if chain.count <= 1

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
      chain = k.to_s.split('.')
      cur = self

      return super if chain.count <= 1

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

    protected

    @@formats = {
      json: JSON,
      yaml: YAML
    }

    def serialize(d)
      @@formats[options[:format]].dump(d)
    end

    def deserialize(d)
      @@formats[options[:format]].load(d) || {}
    end
  end
end
