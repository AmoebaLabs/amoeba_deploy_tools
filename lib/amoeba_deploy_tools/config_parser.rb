require 'inifile'
require 'hashie/mash'

class ConfigParser < Hashie::Mash
  def self.load(filename, **opts)
    new.tap {|c| c.options(filename: filename, **opts) }.restore
  end

  def options(**opts)
    @opts ||= { encoding: 'UTF-8', comment: ';#' }
    @opts.merge! opts
  end

  def restore(**opts)
    options(opts)

    filename = options[:filename]
    return unless filename

    FileUtils.touch filename unless File.exists?(filename) || !options[:create]
    @ini_conf = IniFile.load(filename, options)
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

  def save(**opts)
    options(opts)

    filename = options[:filename]
    return unless filename

    FileUtils.touch filename unless File.exists? filename
    prev_conf = @ini_conf.restore(options) if @ini_conf

    conf = dup
    @ini_conf = IniFile.new

    prev_conf.sections.each do |section|
      if section =~ /^(\S+)\s+"((?:\"|[^"])+)"/
        k1 = $1
        k2 = $2.gsub('\"', '"')
        if conf.key? k1
          if conf[k1].key? k2
            @ini_conf[section].merge!(conf[k1].delete(k2).flatten)
          end

          conf.delete(k1) if conf[k1].empty?
        end
      end
    end if prev_conf

    conf.reject {|k, v| v.class != self.class || v.empty? }.each do |k1, v1|
      conf.delete(k1).each do |k2, v2|
        if v2.class <= self.class
          @ini_conf["#{k1} #{k2.inspect}"].merge!(v2.flatten)
        else
          @ini_conf[k1][k2] = v2
        end
      end
    end

    @ini_conf.merge! conf

    if options[:indent]
      indent = ' ' * 4
      fmt_conf = IniFile.new
      @ini_conf.sections.each do |section|
        fmt_conf[section] = Hash[@ini_conf[section].map {|k, v| [indent + k, v] }]
      end

      fmt_conf.save(options)
    else
      @ini_conf.save(options)
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
