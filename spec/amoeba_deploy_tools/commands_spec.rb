require 'spec_helper'
require 'stringio'

class AmoebaDeployTools
  describe 'Amoeba Commands' do
    def run_cmd(argv)
      $stdout = StringIO.new
      $stderr = StringIO.new

      @status = Amoeba.new(*argv).run(false)

      @stdout = $stdout.tap {|f| f.seek(0) }.read
      @stderr = $stderr.tap {|f| f.seek(0) }.read
    ensure
      $stdout = STDOUT
      $stderr = STDERR
    end

    context 'amoeba' do
      context 'help' do
        subject! { run_cmd %w{amoeba help} }

        it 'should exit with status code 1' do
          expect(@status).to eq(1)
        end
      end
    end
  end
end
