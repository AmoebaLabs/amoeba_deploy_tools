require 'yaml'
require 'fileutils'
require 'hashie/mash'

class AmoebaDeployTools
  class Config < Hashie::Mash
    def self.load(filename, **opts)
      new.tap {|c| c.options(filename: filename, **opts) }.restore
    end

    def options(**opts)
      @opts ||= { format: :yaml }
      @opts.merge! opts
    end

    def restore(**opts)
      options(opts)

      return unless filename = options[:filename]

      File.open(filename) do |fh|
        self.clear.deep_merge! deserialize(fh.read)
      end

      self
    rescue Errno::ENOENT
      FileUtils.touch(filename) and retry if options[:create]
    end

    def save(**opts)
      options(opts)

      return unless filename = options[:filename]

      File.open(filename) do |fh|
        fh.write(serialize(self.to_hash))
      end

      self
    rescue Errno::ENOENT
      FileUtils.touch(filename) and retry if options[:create]
    end

    def to_s
      to_hash.to_s
    end

    protected

    @@formats = {
      json: JSON
      yaml: YAML
    }

    def serialize(d)
      @@formats[options[:format]].dump(d)
    end

    def deserialize(d)
      @@formats[options[:format]].load(d)
    end
  end
end
