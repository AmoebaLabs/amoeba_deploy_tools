require 'yaml'
require 'json'
require 'fileutils'
require 'hashie/mash'

module AmoebaDeployTools
  class Config < Hashie::Mash
    def self.load(filename, opts={})
      opts[:filename] = File.expand_path filename
      Config.new.tap do |c|
        c.restore(opts)
      end
    end

    def self.create(filename, opts={})
      opts.merge!({
        filename: File.expand_path(filename),
        create: true
      })

      Config.new.tap do |c|
        c.options(opts)
      end
    end

    def options(opts=nil)
      @opts ||= { format: :yaml }
      @opts.merge! opts if opts
      @opts
    end

    def restore(opts=nil)
      options(opts)

      return unless filename = options[:filename]

      self.clear.deep_merge! deserialize(File.read(filename))

      self
    rescue Errno::ENOENT
      @new_file = true
      FileUtils.touch(filename) and retry if options[:create]
    end

    def reload!
      restore(filename: options[:filename])
    end

    def new_file?
      !!@new_file
    end

    def save(opts=nil)
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
