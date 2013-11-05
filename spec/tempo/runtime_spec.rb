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

    describe '{{!-- Foo --}}Foo'do
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

  context 'when input wants to print a non-string' do
    describe '{{foo}}' do
      let(:context) { { 'foo' => 1 }}
      it { expect(output).to eq('1') }
    end

    describe '{{foo}}' do
      let(:context) { { 'foo' => { 'bar' => 'baz' } }}
      it { expect(output).to eq('') }
    end

    describe '{{foo}}' do
      let(:context) { { 'foo' => true }}
      it { expect(output).to eq('true') }
    end

    describe '{{foo}}' do
      let(:context) { { 'foo' => false }}
      it { expect(output).to eq('false') }
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

  context 'when input includes a path that starts with a helper' do
    before do
      subject.helpers.register('foo') do
        { 'bar' => 'baz' }
      end
    end

    describe '{{foo.bar}}' do
      it { expect(output).to eq('baz') }
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

  context 'when input includes a scoped statement that is also a helper' do
    let(:context) { { 'foo' => 'context' } }

    before do
      subject.helpers.register('foo') do
        'helper'
      end
    end

    describe '{{this.foo}}' do
      it { pending { expect(output).to eq('context') } }
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

  context 'when input includes an if helper' do
    describe 'truthy values' do
      context 'when the passed value is a non-empty string' do
        describe '{{#if foo}}bar{{else}}baz{{/if}}' do
          let(:context) { { 'foo' => 'true' } }
          it { expect(output).to eq('bar') }
        end
      end

      context 'when the passed value is a collection with elements' do
        describe '{{#if foo}}bar{{else}}baz{{/if}}' do
          let(:context) { { 'foo' => ['one'] } }
          it { expect(output).to eq('bar') }
        end
      end

      context 'when the passed value is true' do
        describe '{{#if foo}}bar{{else}}baz{{/if}}' do
          let(:context) { { 'foo' => true } }
          it { expect(output).to eq('bar') }
        end
      end

      context 'when the passed value is a number' do
        describe '{{#if foo}}bar{{else}}baz{{/if}}' do
          let(:context) { { 'foo' => 1 } }
          it { expect(output).to eq('bar') }
        end
      end

      context 'when the passed value is an object' do
        describe '{{#if foo}}bar{{else}}baz{{/if}}' do
          let(:context) { { 'foo' => Object.new } }
          it { expect(output).to eq('bar') }
        end
      end
    end

    describe 'falsy values' do
      context 'when the passed value is an empty string' do
        describe '{{#if foo}}bar{{else}}baz{{/if}}' do
          let(:context) { { 'foo' => '' } }
          it { expect(output).to eq('baz') }
        end
      end

      context 'when the passed value is a collection with elements' do
        describe '{{#if foo}}bar{{else}}baz{{/if}}' do
          let(:context) { { 'foo' => [] } }
          it { expect(output).to eq('baz') }
        end
      end

      context 'when the passed value is false' do
        describe '{{#if foo}}bar{{else}}baz{{/if}}' do
          let(:context) { { 'foo' => false } }
          it { expect(output).to eq('baz') }
        end
      end

      context 'when the passed value is a nil' do
        describe '{{#if foo}}bar{{else}}baz{{/if}}' do
          let(:context) { { 'foo' => nil } }
          it { expect(output).to eq('baz') }
        end
      end
    end
  end

  context 'when input includes an unless helper' do
    describe 'truthy values' do
      context 'when the passed value is a non-empty string' do
        describe '{{#unless foo}}bar{{else}}baz{{/unless}}' do
          let(:context) { { 'foo' => 'true' } }
          it { expect(output).to eq('baz') }
        end
      end

      context 'when the passed value is a collection with elements' do
        describe '{{#unless foo}}bar{{else}}baz{{/unless}}' do
          let(:context) { { 'foo' => ['one'] } }
          it { expect(output).to eq('baz') }
        end
      end

      context 'when the passed value is true' do
        describe '{{#unless foo}}bar{{else}}baz{{/unless}}' do
          let(:context) { { 'foo' => true } }
          it { expect(output).to eq('baz') }
        end
      end

      context 'when the passed value is a number' do
        describe '{{#unless foo}}bar{{else}}baz{{/unless}}' do
          let(:context) { { 'foo' => 1 } }
          it { expect(output).to eq('baz') }
        end
      end

      context 'when the passed value is an object' do
        describe '{{#unless foo}}bar{{else}}baz{{/unless}}' do
          let(:context) { { 'foo' => Object.new } }
          it { expect(output).to eq('baz') }
        end
      end
    end

    describe 'falsy values' do
      context 'when the passed value is an empty string' do
        describe '{{#unless foo}}bar{{else}}baz{{/unless}}' do
          let(:context) { { 'foo' => '' } }
          it { expect(output).to eq('bar') }
        end
      end

      context 'when the passed value is a collection with elements' do
        describe '{{#unless foo}}bar{{else}}baz{{/unless}}' do
          let(:context) { { 'foo' => [] } }
          it { expect(output).to eq('bar') }
        end
      end

      context 'when the passed value is false' do
        describe '{{#unless foo}}bar{{else}}baz{{/unless}}' do
          let(:context) { { 'foo' => false } }
          it { expect(output).to eq('bar') }
        end
      end

      context 'when the passed value is a nil' do
        describe '{{#unless foo}}bar{{else}}baz{{/unless}}' do
          let(:context) { { 'foo' => nil } }
          it { expect(output).to eq('bar') }
        end
      end
    end
  end

  context 'when input includes an each helper' do
    context 'when the passed value is nil' do
      describe '{{#each foo}}bar{{else}}baz{{/each}}' do
        let(:context) { { 'foo' => nil } }
        it { expect(output).to eq('baz') }
      end
    end

    context 'when the passed value is an empty collection' do
      describe '{{#each foo}}bar{{else}}baz{{/each}}' do
        let(:context) { { 'foo' => [] } }
        it { expect(output).to eq('baz') }
      end
    end

    context 'when the passed value is not a collection' do
      describe '{{#each foo}}bar{{else}}baz{{/each}}' do
        let(:context) { { 'foo' => 'bar' } }
        it { expect(output).to eq('baz') }
      end
    end

    context 'when the passed value is a collection with elements' do
      describe '{{#each foo}}{{this}}. {{else}}baz{{/each}}' do
        let(:context) { { 'foo' => ['foo', 'bar', 'baz'] } }
        it { expect(output).to eq('foo. bar. baz. ') }
      end
    end

    context 'when input uses the @index local' do
      context 'when the passed value is a collection with elements' do
        describe '{{#each foo}}{{@index}} {{this}}. {{else}}baz{{/each}}' do
          let(:context) { { 'foo' => ['foo', 'bar', 'baz'] } }
          it { expect(output).to eq('0 foo. 1 bar. 2 baz. ') }
        end
      end
    end

    context 'when input uses the @key local' do
      context 'when the passed value is a collection with elements' do
        describe '{{#each this}}{{@key}}: {{this}}. {{else}}baz{{/each}}' do
          let(:context) { { 'foo' => 'bar', 'baz' => 'bam' } }
          it { expect(output).to eq('foo: bar. baz: bam. ') }
        end
      end
    end

    context 'when input uses nested each helpers with locals' do
      describe '{{#each this}}{{@key}} ({{@index}}): ({{#each this}}{{@index}} {{this}} {{/each}}), {{/each}}' do
        let(:context) { { 'foo' => ['bar', 'baz', 'bam'], 'baz' => ['bam', 'bar', 'foo'] } }
        it { expect(output).to eq('foo (0): (0 bar 1 baz 2 bam ), baz (1): (0 bam 1 bar 2 foo ), ') }
      end
    end
  end

  context 'when input includes a with helper' do
    describe '{{#with foo}}{{bar}}{{/with}}' do
      let(:context) { { 'foo' => { 'bar' => 'baz' } } }
      it { expect(output).to eq('baz') }
    end
  end

  context 'when input includes a log helper' do
    describe '{{log "This is a message!"}}' do
      it 'should print the given message to STDOUT' do
        io = double
        io.should_receive(:puts).with('This is a message!')
        subject.helpers.register(:log, Tempo::StandardHelperResolver::Log.new(io))
        expect(output).to eq('')
      end
    end
  end

  context 'when input accesses an allowed method' do
    let(:resource) { double(:resource, :foo => 'bar') }
    let(:context_class) do
      Class.new(Tempo::Context).tap do |c|
        c.allows :foo
      end
    end

    describe '{{foo}}' do
      let(:context) { context_class.new(resource) }
      it { expect(output).to eq('bar') }
    end
  end

  context 'when input accesses a protected method' do
    describe '{{foo}}' do
      let(:resource) { double(:resource, :foo => 'bar') }
      let(:context) { Tempo::Context.new(resource) }

      it { expect(output).to eq('') }

      it 'should never call the protected method' do
        expect(resource).to_not receive(:foo)
        output
      end
    end
  end
end