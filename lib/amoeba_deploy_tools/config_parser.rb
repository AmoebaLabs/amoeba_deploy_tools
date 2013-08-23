require 'inifile'
require 'hashie/mash'

class ConfigParser < Hashie::Mash
  def self.load(filename, opts={})
    new.restore(opts.merge filename: filename)
  end

  def restore(opts={})
    @filename = opts[:filename] || @filename

    FileUtils.touch @filename unless File.exists?(@filename) || !opts[:create]
    @ini_conf = IniFile.load(@filename, opts)
    return unless @ini_conf
    self.clear

    @ini_conf.sections.each do |section|
      if section =~ /^\s*(\S+)\s+"((?:\"|[^"])+)"\s*$/
        self.deep_merge! $1 => { $2 => @ini_conf[section] }
      else
        @ini_conf[section].each do |k, v|
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
    return unless  @filename

    FileUtils.touch @filename unless File.exists? @filename
    prev_conf = @ini_conf.restore(filename: @filename) if @ini_conf

    conf = dup
    @ini_conf = IniFile.new

    prev_conf.sections.each do |section|
      if section =~ /^(\S+)\s+"((?:\"|[^"])+)"/
        k1 = $1
        k2 = $2.gsub('\"', '"')
        if conf.key? k1 and conf[k1].key? k2
          @ini_conf[section].merge!(conf[k1].delete(k2).flatten)
        end
      end
    end if prev_conf

    conf.reject {|k, v| v.empty?}.each do |k1, v1|
      v1.each do |k2, v2|
        @ini_conf["#{k1} #{k2.inspect}"].merge!(v2.flatten)
      end
    end

    if opts[:indent]
      indent = ' ' * 4
      fmt_conf = IniFile.new
      @ini_conf.sections.each do |section|
        @ini_conf[section].each do |k, v|
          fmt_conf[section][indent + k] = v
        end
      end

      fmt_conf.save(opts.merge filename: @filename)
    else
      @ini_conf.save(opts.merge filename: @filename)
    end

    self
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
