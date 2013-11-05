require 'spec_helper'

describe 'basics' do
  let(:runtime) { Tempo::Runtime.new }
  let(:input) { self.class.description }
  let(:context) { {} }

  subject { runtime.render(input, context) }

  context 'handling most basic example' do
    describe '{{foo}}' do
      let(:context) { { 'foo' => 'foo' } }
      it { should eq('foo') }
    end
  end

  context 'handling escaping' do
    let(:context) { { 'foo' => 'food' } }

    describe("\\{{foo}}") do
      it { should eq("{{foo}}") }
    end

    describe("content \\{{foo}}") do
      it { should eq("content {{foo}}") }
    end

    describe("\\\\{{foo}}") do
      it { should eq("\\food") }
    end

    describe("content \\\\{{foo}}") do
      it { should eq("content \\food") }
    end

    describe("\\\\ {{foo}}") do
      it { should eq("\\\\ food") }
    end
  end

  context 'handling a basic context' do
    let(:context) { { 'cruel' => 'cruel', 'world' => 'world' } }

    describe "Goodbye\n{{cruel}}\n{{world}}!" do
      it { should eq("Goodbye\ncruel\nworld!") }
    end
  end

  context 'handling undefined context' do
    describe "Goodbye\n{{cruel}}\n{{world.bar}}!" do
      it { should eq("Goodbye\n\n!") }
    end

    describe '{{#unless foo}}Goodbye{{../test}}{{test2}}{{/unless}}' do
      it { should eq('Goodbye') }
    end
  end

  context 'handling comments' do
    let(:context) { { 'cruel' => 'cruel', 'world' => 'world' } }

    describe "{{! Goodbye}}Goodbye\n{{cruel}}\n{{world}}!" do
      it { should eq("Goodbye\ncruel\nworld!") }
    end
  end

  context 'handling booleans' do
    context 'when boolean is true' do
      let(:context) { { 'goodbye' => true, 'world' => 'world' } }

      describe '{{#goodbye}}GOODBYE {{/goodbye}}cruel {{world}}!' do
        it { should eq('GOODBYE cruel world!') }
      end
    end

    context 'when boolean is false' do
      let(:context) { { 'goodbye' => false, 'world' => 'world' } }

      describe '{{#goodbye}}GOODBYE {{/goodbye}}cruel {{world}}!' do
        it { should eq('cruel world!') }
      end
    end
  end

  context 'handling zeros' do
    let(:context) { { 'num1' => 42, 'num2' => 0 } }

    describe 'num1: {{num1}}, num2: {{num2}}' do
      it { should eq('num1: 42, num2: 0') }
    end

    context 'using the current context expression' do
      let(:context) { 0 }

      describe 'num: {{.}}' do
        it { pending { should eq('num: 0') } }
      end
    end

    context 'using a path' do
      let(:context) { { 'num1' => { 'num2' => 0 } } }

      describe 'num: {{num1/num2}}' do
        it { should eq('num: 0') }
      end
    end
  end

  context 'handling newlines' do
    describe "Alan's\nTest" do
      it { should eq("Alan's\nTest") }
    end

    describe "Alan's\rTest" do
      it { should eq("Alan's\rTest") }
    end
  end

  context 'handling escaped text' do
    describe "Awesome's" do
      it { should eq("Awesome's") }
    end

    describe "Awesome\\" do
      it { should eq("Awesome\\") }
    end

    describe "Awesome\\\\ foo" do
      it { should eq("Awesome\\\\ foo") }
    end

    describe "Awesome {{foo}}" do
      let(:context) { { 'foo' => '\\' } }
      it { should eq("Awesome \\") }
    end

    describe ' " " ' do
      it { should eq(' " " ') }
    end
  end

  context 'handling escaped expressions' do
    let(:context) { { 'awesome' => "&\"'`\\<>" } }

    describe '{{{awesome}}}' do
      it { should eq("&\"'`\\<>") }
    end

    describe '{{&awesome}}' do
      it { should eq("&\"'`\\<>") }
    end

    describe '{{awesome}}' do
      it { should eq('&amp;&quot;&#39;&#x60;\\&lt;&gt;') }
    end

    describe '{{awesome}}' do
      let(:context) { { 'awesome' => 'Escaped, <b> looks like: &lt;b&gt;' } }
      it { should eq('Escaped, &lt;b&gt; looks like: &amp;lt;b&amp;gt;') }
    end
  end

  context 'handling returned safe-strings' do
    describe '{{awesome}}' do
      let(:context) { { 'awesome' => lambda { Tempo::SafeString.new("&\"\\<>") } } }
      it { should eq("&\"\\<>") }
    end
  end

  context 'handling expressions with arguments' do
    describe '{{awesome frank}}' do
      let(:context) { { 'awesome' => lambda { |arg| arg }, 'frank' => 'Frank' } }
      it { pending { should eq('Frank') } }
    end

    describe '{{awesome Frank}}' do
      let(:context_class) do
        Class.new(Tempo::Context).tap do |klass|
          klass.class_eval <<-RUBY
            allows :awesome

            def awesome(arg)
              arg
            end
          RUBY
        end
      end
      let(:context) { { 'awesome' => context_class.new(nil), 'frank' => 'Frank' } }

      it { pending { should eq('Frank') } }
    end
  end

  context 'handling block expressions with arguments' do
    describe '{{#awesome 1}}inner {{.}}{{/awesome}}' do
      let(:context) { { 'awesome' => lambda { |arg| yield(arg) } } }
      it { pending { should eq('inner 1') } }
    end

    describe '{{#awesome 1}}inner {{.}}{{/awesome}}' do
      let(:context_class) do
        Class.new(Tempo::Context).tap do |klass|
          klass.class_eval <<-RUBY
            allows :awesome

            def awesome(arg)
              yield(arg)
            end
          RUBY
        end
      end
      let(:context) { { 'awesome' => context_class.new(nil) } }

      it { pending { should eq('inner 1') } }
    end
  end

  context 'handling block expressions' do
    describe '{{#awesome}}inner{{/awesome}}' do
      let(:context) { { 'awesome' => lambda { yield } } }
      it { pending { should eq('inner') } }
    end

    describe '{{#awesome}}inner{{/awesome}}' do
      let(:context_class) do
        Class.new(Tempo::Context).tap do |klass|
          klass.class_eval <<-RUBY
            allows :awesome

            def awesome
              yield
            end
          RUBY
        end
      end
      let(:context) { { 'awesome' => context_class.new(nil) } }

      it { should eq('inner') }
    end
  end

  context 'handling paths with hypens' do
    context 'when context is a hash' do
      describe '{{foo-bar}}' do
        let(:context) { { 'foo-bar' => 'baz' } }
        it { should eq('baz') }
      end

      describe '{{foo.foo-bar}}' do
        let(:context) { { 'foo' => { 'foo-bar' => 'baz' } } }
        it { should eq('baz') }
      end

      describe '{{foo/foo-bar}}' do
        let(:context) { { 'foo' => { 'foo-bar' => 'baz' } } }
        it { should eq('baz') }
      end
    end

    context 'when context is an object' do
      let(:context_class) do
        Class.new(Tempo::Context).tap do |klass|
          klass.class_eval <<-RUBY
            allows :foo_bar

            def foo_bar
              'baz'
            end
          RUBY
        end
      end

      describe '{{foo-bar}}' do
        let(:context) { context_class.new(nil) }
        it { pending { should eq('baz') } }
      end

      describe '{{foo.foo-bar}}' do
        let(:context) { { 'foo' => context_class.new(nil) } }
        it { pending { should eq('baz') } }
      end

      describe '{{foo/foo-bar}}' do
        let(:context) { { 'foo' => context_class.new(nil) } }
        it { pending { should eq('baz') } }
      end
    end
  end

  context 'handling nested paths' do
    let(:context) { { 'alan' => { 'expression' => 'beautiful' } } }

    describe 'Goodbye {{alan/expression}} world!' do
      it { should eq('Goodbye beautiful world!') }
    end
  end

  context 'handling nested paths with empty string value' do
    let(:context) { { 'alan' => { 'expression' => '' } } }

    describe 'Goodbye {{alan/expression}} world!' do
      it { should eq('Goodbye  world!') }
    end
  end

  context 'handling literal paths' do
    describe 'Goodbye {{[@alan]/expression}} world!' do
      let(:context) { { '@alan' => { 'expression' => 'beautiful' } } }

      it { pending { should eq('Goodbye beautiful world!') } }
    end

    describe 'Goodbye {{[foo bar]/expression}} world!' do
      let(:context) { { 'foo bar' => { 'expression' => 'beautiful' } } }

      it { pending { should eq('Goodbye beautiful world!') } }
    end
  end

  context 'handling literal references' do
    describe 'Goodbye {{[foo bar]}} world!' do
      let(:context) { { 'foo bar' => 'beautiful' } }

      it { pending { should eq('Goodbye beautiful world!') } }
    end
  end

  context 'handling current context path and helpers' do
    before do
      runtime.helpers.register(:helper) { 'awesome' }
    end

    describe 'test: {{.}}' do
      it { should eq('test: ') }
    end
  end

  context 'handling complex but empty paths' do
    describe '{{person/name}}' do
      let(:context) { { 'person' => { 'name' => nil } } }
      it { should eq('') }
    end

    describe '{{person/name}}' do
      let(:context) { { 'person' => {} } }
      it { should eq('') }
    end
  end

  context 'handling the this keyword in paths' do
    describe '{{#goodbyes}}{{this}}{{/goodbyes}}' do
      let(:context) { { 'goodbyes' => ['goodbye', 'Goodbye', 'GOODBYE'] } }

      it { should eq('goodbyeGoodbyeGOODBYE') }
    end

    describe '{{#hellos}}{{this/text}}{{/hellos}}' do
      let(:context) do
        {
          'hellos' => [
            { 'text' => 'hello' },
            { 'text' => 'Hello' },
            { 'text' => 'HELLO' }
          ]
        }
      end

      it { pending { should eq('helloHelloHELLO') } }
    end
  end

  context 'handling the this keyword inside nested paths' do
    describe '{{#hellos}}{{text/this/foo}}{{/hellos}}' do
      let(:context) do
        {
          'hellos' => [
            { 'text' => 'hello' },
            { 'text' => 'Hello' },
            { 'text' => 'HELLO' }
          ]
        }
      end

      it 'raises an exception' do
        expect { subject }.to raise_error
      end
    end
  end

  context 'handling the this keyword in helpers' do
    before do
      runtime.helpers.register(:foo) { |arg| "bar #{arg}" }
    end

    describe '{{#goodbyes}}{{foo this}}{{/goodbyes}}' do
      let(:context) { { 'goodbyes' => ['goodbye', 'Goodbye', 'GOODBYE'] } }

      it { should eq('bar goodbyebar Goodbyebar GOODBYE') }
    end

    describe '{{#hellos}}{{foo this/text}}{{/hellos}}' do
      let(:context) do
        {
          'hellos' => [
            { 'text' => 'hello' },
            { 'text' => 'Hello' },
            { 'text' => 'HELLO' }
          ]
        }
      end

      it { should eq('bar hellobar Hellobar HELLO') }
    end
  end

  context 'handling the this keyword inside helper params' do
    describe '{{#hellos}}{{foo text/this/foo}}{{/hellos}}' do
      let(:context) do
        {
          'hellos' => [
            { 'text' => 'hello' },
            { 'text' => 'Hello' },
            { 'text' => 'HELLO' }
          ]
        }
      end

      it 'raises an exception' do
        expect { subject }.to raise_error
      end
    end
  end
end