require 'tempfile'
require 'pathname'

def with_tmpfile(content=nil)
  tmpf = Tempfile.new 'spec'
  tmpf.write content
  tmpf.close

  results = yield tmpf.path, tmpf

  tmpf.unlink
  results
end

def dedent(s)
  indent = s.split("\n").reject {|l| l =~ /^\s*$/}.map {|l| l.index /\S/ }.min
  s.sub(/^\n/, '').gsub(/ +$/, '').gsub(/^ {#{indent}}/, '')
end

def indent(s, indent=4)
  s.gsub(/^/, ' ' * indent)
end

def require_all(path)
  if Pathname.new(path).relative?
    Dir.glob File.join(path, '*.rb')
  else
    $LOAD_PATH.find {|p| Dir.glob File.join(p, path, '*.rb')}
  end.map {|f| require Dir.absolute_path(f)}
end

class Exception
  def bt
    backtrace.map do |l|
      cwd = Dir.pwd
      l.start_with?(cwd) ? l.sub(cwd, '.') : l
    end
  end
end
