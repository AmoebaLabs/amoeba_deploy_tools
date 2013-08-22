require 'tempfile'

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


