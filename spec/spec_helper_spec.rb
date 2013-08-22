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
