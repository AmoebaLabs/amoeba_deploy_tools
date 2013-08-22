require 'spec_helper'
require 'amoeba-deploy-tools/config'

describe ConfigParser do
  it 'correctly parses subsection names' do
    config = loadconfig %{
      [foo "bar"]
          baz = garply
      [foo "buz"]
          biz = booz
    }

    expect(config).to be_instance_of(ConfigParser)
    expect(config.to_hash).to eq({
      'foo' => {
        'bar' => { 'baz' => 'garply' },
        'buz' => { 'biz' => 'booz' }
      }
    })
    expect(config['foo']['bar']).to eq('baz' => 'garply')
    expect(config['foo']['buz']['biz']).to eq('booz')
  end

  it 'ignores spaces around section names' do
    config = loadconfig %{
      [  foo "bar"  ]
          baz = garply
    }

    expect(config).to be_instance_of(ConfigParser)
    expect(config.to_hash).to eq({ 'foo' => { 'bar' => { 'baz' => 'garply' } } })
  end

  it 'correctly flattens keys using dot-notation' do
    config = ConfigParser.new
    config.foo!.bar!.baz = 'quux'
    config.foo!.garply!.biz = 'buz'
    config.foo!.bar!.garply = 'quz'

    with_tmpfile do |f, fh|
      config.save(filename: f)
      expect(fh.open.read).to eq(dedent %{
        [foo "bar"]
          baz = quux
          garply = quz

        [foo "garply"]
          biz = buz

      }.gsub(/ +/, ' '))
    end
  end

  it 'correctly inserts new records into existing file' do
    config_content = %{
      [a]
          b.c = foo
      [a "b"]
          d = garply
      [foo "buz"]
          biz = booz
    }
    with_tmpfile dedent(config_content) do |f, fh|
      config = ConfigParser.load(f)
      config.foo.buz.baaz = 'guux'
      config.save

      expect(fh.open.read).to eq(dedent %{
        [a "b"]
            c = foo
            d = garply

        [foo "buz"]
            biz = booz
            baaz = guux

      }.gsub(/ +/, ' '))
    end
  end

  it 'correctly indents when writing out to a file' do
    config_content = %{
      [a]
          b.c = foo
      [a "b"]
          d = garply
      [foo "buz"]
          biz = booz
    }
    with_tmpfile dedent(config_content) do |f, fh|
      config = ConfigParser.load(f)
      config.save indent: true

      expect(fh.open.read).to eq(dedent %{
        [a "b"]
            c = foo
            d = garply

        [foo "buz"]
            biz = booz

      })
    end
  end

  def loadconfig(content)
    with_tmpfile dedent(content) do |f|
      ConfigParser.load(f)
    end
  end
end
