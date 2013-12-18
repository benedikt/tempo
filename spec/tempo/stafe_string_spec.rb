require 'spec_helper'

describe Tempo::SafeString do
  it { should be_kind_of(String) }

  describe '#to_s' do
    it 'should return a safe string' do
      expect(subject.to_s).to be_kind_of(Tempo::SafeString)
    end
  end
end