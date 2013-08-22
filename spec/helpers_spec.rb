require 'spec_helper'

describe :dedent do
  it 'correctly removes indentation' do
    expect(dedent %{
    foo
      bar
    baz
        garply
    }).to eq("foo\n  bar\nbaz\n    garply\n")
  end
end

describe :indent do
  it 'indents each line by the specified amount' do
    expect(indent("foo\n  bar\nbaz\n    garply\n", 3)).to eq("   foo\n     bar\n   baz\n       garply\n")
  end
end
