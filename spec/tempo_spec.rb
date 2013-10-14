require 'spec_helper'

describe Tempo do

  describe '.render' do
    let(:template) { '{{foo}}' }
    let(:context) { { 'foo' => 'bar' } }
    let(:runtime) { Tempo::Runtime.new }

    before do
      Tempo.runtime = nil
      Tempo::Runtime.stub(:new => runtime)
    end

    it 'should create a new runtime' do
      expect(Tempo::Runtime).to receive(:new)
        .and_return(runtime)

      Tempo.render(template, context)
    end

    it 'should keep the created runtime' do
      expect(Tempo::Runtime).to receive(:new)
        .and_return(runtime)
        .once

      2.times { Tempo.render(template, context) }
    end

    it 'should render a new template' do
      expect(runtime).to receive(:render)
        .with(template, context)

      Tempo.render(template, context)
    end

    it 'should not require a context' do
      expect(runtime).to receive(:render)
        .with(template, {})

      Tempo.render(template)
    end
  end

end