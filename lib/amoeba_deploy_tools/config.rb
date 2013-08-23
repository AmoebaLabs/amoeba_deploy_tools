require 'yaml'
require 'fileutils'
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
    rescue Errno::ENOENT
      FileUtils.touch(filename) and retry if options[:create]
    end

    def save(**opts)
      options(opts)

      filename = options[:filename]
      return unless filename

      File.open(filename) do |fh|
        fh.write(YAML.dump(self.to_hash))
      end

      self
    rescue Errno::ENOENT
      FileUtils.touch(filename) and retry if options[:create]
    end

    def to_s
      to_hash.to_s
    end
  end
end
