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

def require_dir(path)
  require_glob(File.join(path, '*.rb'))
end

def require_glob(glob_path)
  basedir = File.dirname(caller(1).first.split(':')[0])
  if Pathname.new(glob_path).relative?
    Dir.glob File.absolute_path(glob_path, basedir)
  else
    files = []
    $LOAD_PATH.find {|p| !(files = Dir.glob File.join(p, glob_path)).empty? }

    files
  end.map {|f| require File.absolute_path(f, basedir)}
end

class Exception
  def bt
    backtrace.map do |l|
      cwd = Dir.pwd
      l.start_with?(cwd) ? l.sub(cwd, '.') : l
    end
  end
end
