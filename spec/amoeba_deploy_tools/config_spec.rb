require 'spec_helper'
require 'yaml'

describe AmoebaDeployTools::Config do
  let (:config) { subject }

  let :given do
    {'foo' => 'bar'}
  end

  before merge: true do
    config.merge! given
  end

  it 'saves config files', :merge do
    with_tmpfile do |f|
      config.save filename: f
    end

    expect(config).to eq(given)
  end

  it 'loads config files' do
    with_tmpfile YAML.dump(given) do |f|
      config.restore filename: f
    end

    expect(config).to eq(given)
  end

  context 'with a nested structure' do
    let :given do
      {'foo' => {'bar' => {'baz' => 'garply'}}}
    end

    it 'expands dotted keys' do
      config['foo.bar.baz'] = 'garply'

      expect(config).to eq(given)
    end

    it 'flattens into dotted keys', :merge do
      expect(config.flatten).to eq({
        'foo.bar.baz' => 'garply'
      })
    end
  end
end
