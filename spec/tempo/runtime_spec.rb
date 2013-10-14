require 'spec_helper'

describe Tempo::Runtime do

  let(:input) { self.class.description }
  let(:context) { {} }

  subject { described_class.new }
  let(:output) { subject.render(input, context) }

  describe '#initialize' do
    it 'should pass the runtime instance to a given block' do
      expect { |block| described_class.new(&block) }
        .to yield_with_args(an_instance_of(described_class))
    end
  end

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

  context 'when input includes a partial' do
    let(:context) { { 'foo' => 'bar', 'bar' => { 'foo' => 'baz' } } }

    context 'when the partial is known' do
      before do
        subject.partials.register('partial', '{{foo}}')
      end

      describe '{{> partial}}' do
        it { expect(output).to eq('bar')}
      end

      describe '{{> partial bar}}' do
        it { expect(output).to eq('baz') }
      end
    end

    context 'when the partial is not known' do
      describe '{{> partial}}' do
        it { expect(output).to eq('Missing partial \'partial\'') }
      end
    end
  end

  context 'when input includes a simple helper statement' do
    context 'when the helper is known' do
      before do
        subject.helpers.register('helper') do
          'Helper'
        end
      end

      describe '{{helper}}' do
        it { expect(output).to eq('Helper') }
      end
    end

    context 'when the helper is not known' do
      describe '{{helper}}' do
        it { expect(output).to eq('') }
      end
    end
  end

  context 'when input includes a path that has a segment named like a helper' do
    let(:context) { { 'foo' => { 'helper' => 'bar' } } }

    before do
      subject.helpers.register('helper') do
        'Helper'
      end
    end

    describe '{{foo.helper}}' do
      it { expect(output).to eq('bar') }
    end
  end

  context 'when input includes a statement that is both a helper and in the context' do
    let(:context) { { 'foo' => 'context' } }

    before do
      subject.helpers.register('foo') do
        'helper'
      end
    end

    describe '{{foo}}' do
      it { expect(output).to eq('helper') }
    end
  end

  context 'when input includes a helper with parameters' do
    before do
      subject.helpers.register('add') do |a, b|
        a + b
      end
    end

    describe '{{add 1 2}}' do
      it { expect(output).to eq('3') }
    end
  end

  context 'when input includes a helper with options' do
    before do
      subject.helpers.register('title') do |title, options|
        title.empty? ? options['default'] : title
      end
    end

    describe '{{title foo default="Default title"}}' do
      it { expect(output).to eq('Default title') }
    end
  end
end