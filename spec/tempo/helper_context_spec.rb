require 'spec_helper'

describe Tempo::HelperContext do

  let(:helper) { lambda { 'Helper' } }

  describe '#register' do
    it 'should register the given helper' do
      subject.register(:example, &helper)
      expect(subject.lookup(:example)).to eq(helper)
    end

    it 'should not differentiate between String and Symbol' do
      subject.register('example', &helper)
      expect(subject.lookup(:example)).to eq(helper)
    end

    it 'should replace registered helpers with the same name' do
      subject.register(:example) { 'Demo' }
      subject.register(:example, &helper)

      expect(subject.lookup(:example)).to eq(helper)
    end
  end

  describe '#lookup' do
    context 'when the helper exists' do
      before { subject.register(:example, helper) }

      it 'should return the helper' do
        expect(subject.lookup(:example)).to eq(helper)
      end
    end

    context 'when the helper does not exist' do
      it 'should not return anything' do
        expect(subject.lookup(:example)).to_not be
      end
    end
  end
end