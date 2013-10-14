require 'spec_helper'

describe Tempo::PartialContext do

  let(:partial) { 'Example' }

  describe '#register' do
    it 'should register the given partial' do
      subject.register(:example, partial)
      expect(subject.lookup(:example)).to eq(partial)
    end

    it 'should not differentiate between String and Symbol' do
      subject.register('example', partial)
      expect(subject.lookup(:example)).to eq(partial)
    end

    it 'should replace registered partials with the same name' do
      subject.register(:example, 'Demo')
      subject.register(:example, partial)

      expect(subject.lookup(:example)).to eq(partial)
    end
  end

  describe '#lookup' do
    context 'when the partial exists' do
      before { subject.register(:example, partial) }

      it 'should return the partial' do
        expect(subject.lookup(:example)).to eq(partial)
      end
    end

    context 'when the partial does not exist' do
      it 'should not return anything' do
        expect(subject.lookup(:example)).to_not be
      end
    end
  end
end