require 'spec_helper'
require 'stringio'

class AmoebaDeployTools
  describe 'Amoeba Commands' do
    def run_cmd(argv)
      $stdout = StringIO.new
      $stderr = StringIO.new

      object = Amoeba.new(*argv).tap {|c| c.run(false) }

      @stdout = $stdout.tap {|f| f.seek(0) }.read
      @stderr = $stderr.tap {|f| f.seek(0) }.read
    ensure
      $stdout = STDOUT
      $stderr = STDERR

      return object
    end

    def self.context(*a, **kw)
      if a.first.is_a? Array
        kw[:argv] = a[0]
        a[0] = "[#{a[0].join(' ')}]"
      end

      super
    end

    subject! { run_cmd(example.metadata[:argv]) }

    shared_examples require_kitchen: true do
      context 'when missing kitchen' do
        its (:status) { should eq(1) }
      end
    end

    context %w{amoeba help} do
      its (:status) { should eq(1) }
    end

    context %w{amoeba node list}, :require_kitchen do
    end
  end
end
