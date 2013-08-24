require 'spec_helper'

class AmoebaDeployTools
  describe Amoeba do
    context '#help' do
      subject { Amoeba.new(:help) }
      it { should raise_error SystemExit }
    end
  end

  describe Amoeba::Node do
    subject { described_class }
    it { should eq(Amoeba::Node) }
    it { should raise_error SystemExit }
  end
end
