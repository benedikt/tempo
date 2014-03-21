require 'spec_helper'

describe Tempo::Context do

  let(:resource) { double(:title => 'Demo', :content => 'Demo Content') }

  let(:context) do
    Class.new(Tempo::Context).tap do |klass|
      klass.allows :title
    end
  end

  subject { context.new(resource) }

  describe '#initialize' do
    it 'should accept a resource' do
      expect { subject }.to_not raise_error
    end
  end

  describe 'generated methods' do
    it { should have_invokable_method(:title) }
    it { should_not have_invokable_method(:content) }
    it { should_not have_invokable_method(:missing) }

    describe '#title' do
      it 'should return a new Tempo::Context instance' do
        expect(subject.invoke('title')).to be_kind_of(Tempo::Context)
      end
    end

    describe '#content' do
      it 'should return nothing' do
        expect(subject.invoke('content')).to_not be
      end
    end

    describe '#missing' do
      it 'should return nothing' do
        expect(subject.invoke('content')).to_not be
      end
    end
  end

  describe '#to_s' do
    it 'should return an empty string' do
      expect(subject.to_s).to eq('')
    end
  end

  describe '#inspect' do
    it 'should make clear that the resource is wrapped with a context' do
      expect(subject.inspect).to eq("#<#{context} for #{resource.inspect}>")
    end
  end

  describe '#eql?' do
    it 'should be true for contexts wrapping the same resource' do
      expect(context.new(resource)).to eql(subject)
    end

    it 'should be false for context wrapping different resources' do
      expect(context.new("example")).not_to eql(subject)
    end
  end

end