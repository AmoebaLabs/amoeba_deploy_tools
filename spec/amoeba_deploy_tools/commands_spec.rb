require 'spec_helper'
require 'stringio'
require 'fileutils'

class AmoebaDeployTools
  describe 'Amoeba command' do
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

    @@subject = nil
    def rerun_cmd
      @@subject = run_cmd(example.metadata[:argv])
    end

    subject { rerun_cmd }
    before { rerun_cmd }

    shared_context require_kitchen: true do
      around do |example|
        in_tmpdir do
          %w(
            .amoeba
            .amoeba/nodes
            .amoeba/roles
          ).map {|p| Dir.mkdir p}

          example.metadata[:nodes].each do |d|
            FileUtils.touch ".amoeba/nodes/#{d}.json"
          end if example.metadata[:nodes].is_a? Enumerable

          example.run
        end
      end

      context 'when missing kitchen' do
        before { FileUtils.rm_rf '.amoeba' }

        its (:status) { should eq(1) }
      end
    end

    context %w(help) do
      its (:cmd) { should eq(:amoeba) }
      its (:subcmd) { should eq(:help) }

      its (:status) { should eq(1) }
    end

    context %w(node list), :require_kitchen do
      its (:cmd) { should eq(:node) }
      its (:subcmd) { should eq(:list) }

      context 'without nodes' do
        it 'returns empty' do
          expect(@stdout).to eq('')
        end

        its (:status) { should eq(0) }
      end

      context 'with nodes', nodes: %w( a.example.com b.example.com ) do
        it 'lists nodes' do
          expect(@stdout).to eq(example.metadata[:nodes].map {|n| n + "\n"}.join)
        end

        its (:status) { should eq(0) }
      end
    end
  end
end
