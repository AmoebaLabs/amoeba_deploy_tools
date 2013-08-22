require 'inifile'
require 'fileutils'
require 'hashie/mash'

class ConfigParser < Hashie::Mash
  def self.load(filename, opts={})
    new.restore(opts.merge filename: filename)
  end

  def restore(opts={})
    @filename = opts[:filename] || @filename
    ini_conf = IniFile.load(@filename, opts)
    self.clear

    ini_conf.sections.each do |section|
      if section =~ /^\s*(\S+)\s+"((?:\"|[^"])+)"\s*$/
        self.deep_merge! $1 => { $2 => ini_conf[section] }
      else
        ini_conf[section].each do |k, v|
          chain = k.split('.').unshift(section)
          cur = self

          for c in chain[0..-2]
            cur = cur.initializing_reader(c)
          end

          cur[chain[-1]] = v
        end
      end
    end

    self
  end

  def save(opts={})
    @filename = opts[:filename] || @filename

    if @filename
      conf = dup
      ini_conf = IniFile.new
      IniFile.load(@filename).sections.each do |section|
        if section =~ /^(\S+)\s+"((?:\"|[^"])+)"/
          k1 = $1
          k2 = $2.gsub('\"', '"')
          if conf.key?(k1) and conf[k1].key?(k2)
            ini_conf[section].merge!(conf[k1].delete(k2).flatten)
          end
        end
      end

      conf.reject {|k, v| v.empty?}.each do |k1, v1|
        v1.each do |k2, v2|
          ini_conf["#{k1} #{k2.inspect}"].merge!(v2.flatten)
        end
      end

      if opts[:indent]
        indent = ' ' * 4
        new_conf = IniFile.new
        ini_conf.sections.each do |section|
          ini_conf[section].each do |k, v|
            new_conf[section][indent + k] = v
          end
        end

        new_conf.write(opts.merge filename: @filename)
      else
        ini_conf.write(opts.merge filename: @filename)
      end

      self
    end
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
