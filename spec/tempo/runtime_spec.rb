require 'spec_helper'

describe Tempo::Runtime do

  let(:input) { self.class.description }
  let(:context) { {} }

  subject { described_class.new }
  let(:output) { subject.render(input, context) }

  context 'when input includes a simple expression' do
    describe '{{foo}}' do
      let(:context) { { 'foo' => 'Hello' } }
      it { expect(output).to eq('Hello') }
    end
  end

  context 'when input includes a simple path expression' do
    let(:context) { { 'foo' => 'Hello', 'bar' => { 'baz' => 'World' } } }

    describe '{{bar.baz}}' do
      it { expect(output).to eq('World') }
    end

    describe '{{bar/baz}}' do
      it { expect(output).to eq('World') }
    end

    describe '{{foo}} {{bar.baz}}' do
      it { expect(output).to eq('Hello World') }
    end
  end

  context 'when input includes comments' do
    describe '{{! Foo}}Foo' do
      it { expect(output).to eq('Foo') }
    end
  end

  context 'when context includes entities' do
    describe '{{foo}}' do
      let(:context) { { 'foo' => '&"\'`\\<>' } }
      it { expect(output).to eq('&amp;&quot;&#39;&#x60;\\&lt;&gt;') }
    end

    describe '{{description}}' do
      let(:context) { { 'description' => 'Escaped, <b> looks like &lt;b&gt;' } }
      it { expect(output).to eq('Escaped, &lt;b&gt; looks like &amp;lt;b&amp;gt;') }
    end
  end

  context 'when input includes an unescaped statement' do
    let(:context) { { 'foo' => '&"\\<>' } }

    describe '{{{foo}}}' do
      it { expect(output).to eq('&"\\<>') }
    end

    describe '{{&foo}}' do
      it { expect(output).to eq('&"\\<>') }
    end
  end

  context 'when input includes a conditial' do
    let(:context) { { 'foo' => 'Hello', 'bar' => { 'baz' => 'World' } } }

    describe '{{#foo}}Hello{{/foo}} World' do
      it { expect(output).to eq('Hello World') }
    end

    describe '{{#foo}}Hello{{else}}Goodbye{{/foo}} World' do
      it { expect(output).to eq('Hello World') }
    end

    describe '{{^foo}}Hello{{/foo}} World' do
      it { expect(output).to eq(' World') }
    end

    describe '{{^foo}}Hello{{else}}Goodbye{{/foo}} World' do
      it { expect(output).to eq('Goodbye World') }
    end
  end

  context 'when input includes a collection' do
    let(:context) { { 'foo' => ['bar', 'baz', 'bam', 'bat'] } }

    describe '{{#foo}}{{this}}. {{/foo}}' do
      it { expect(output).to eq('bar. baz. bam. bat. ') }
    end
  end

  context 'when input includes unknown statements' do
    let(:context) { { 'foo' => 'bar' } }

    describe '{{bar}}' do
      it { expect(output).to eq('') }
    end
  end
end