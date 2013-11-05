require 'spec_helper'

describe 'builtin helpers' do
  let(:runtime) { Tempo::Runtime.new }
  let(:input) { self.class.description }
  let(:context) { {} }

  subject { runtime.render(input, context) }

  describe '#if' do
    let(:input) { '{{#if goodbye}}GOODBYE {{/if}}cruel {{world}}!' }

    context 'with boolean argument' do
      context 'when true' do
        let(:context) { { 'goodbye' => true, 'world' => 'world' } }
        it { should eq('GOODBYE cruel world!') }
      end

      context 'when false' do
        let(:context) { { 'goodbye' => false, 'world' => 'world' } }
        it { should eq('cruel world!') }
      end
    end

    context 'with string argument' do
      context 'when non-empty' do
        let(:context) { { 'goodbye' => 'dummy', 'world' => 'world' } }
        it { should eq('GOODBYE cruel world!') }
      end

      context 'when empty' do
        let(:context) { { 'goodbye' => '', 'world' => 'world' } }
        it { should eq('cruel world!') }
      end
    end

    context 'with undefined argument' do
      let(:context) { { 'world' => 'world' } }
      it { should eq('cruel world!') }
    end

    context 'with array argument' do
      context 'when non-empty' do
        let(:context) { { 'goodbye' => ['foo'], 'world' => 'world' } }
        it { should eq('GOODBYE cruel world!') }
      end

      context 'when empty' do
        let(:context) { { 'goodbye' => [], 'world' => 'world' } }
        it { should eq('cruel world!') }
      end
    end

    context 'when zero argument' do
      let(:context) { { 'goodbye' => 0, 'world' => 'world' } }

      context 'when includeZero is not defined' do
        it { pending { should eq('cruel world!') } }
      end

      context 'when includeZero is true' do
        let(:input) { '{{#if goodbye includeZero=true}}GOODBYE {{/if}}cruel {{world}}!' }
        it { should eq('GOODBYE cruel world!') }
      end
    end
  end

  describe '#with' do
    describe '{{#with person}}{{first}} {{last}}{{/with}}' do
      let(:context) { { 'person' => { 'first' => 'Alan', 'last' => 'Johnson' } } }
      it { should eq('Alan Johnson') }
    end
  end

  describe '#each' do
    context 'when array argument' do
      let(:input) { '{{#each goodbyes}}{{text}}! {{/each}}cruel {{world}}!' }

      context 'when non-empty' do
        let(:context) { { 'goodbyes' => [{ 'text' => 'goodbye' }, { 'text' => 'Goodbye' }, { 'text' => 'GOODBYE' }], 'world' => 'world' } }
        it { should eq('goodbye! Goodbye! GOODBYE! cruel world!') }
      end

      context 'when empty' do
        let(:context) { { 'goodbyes' => [], 'world' => 'world' } }
        it { should eq('cruel world!') }
      end
    end

    context 'when using @key' do
      describe '{{#each goodbyes}}{{@key}}. {{text}}! {{/each}}cruel {{world}}!' do
        let(:context) { { 'goodbyes' => [{ '<b>#1</b>' => 'goodbye' }, { '2' => 'Goodbye' }], 'world' => 'world' } }
        it { pending { should eq('&lt;b&gt;#1&lt;/b&gt;. goodbye! 2. GOODBYE! cruel world!') } }
      end
    end

    context 'when using @index' do
      describe '{{#each goodbyes}}{{@index}}. {{text}}! {{/each}}cruel {{world}}!' do
        let(:context) { { 'goodbyes' => [{ 'text' => 'goodbye' }, { 'text' => 'Goodbye' }, { 'text' => 'GOODBYE' }], 'world' => 'world' } }
        it { should eq('0. goodbye! 1. Goodbye! 2. GOODBYE! cruel world!') }
      end
    end

    context 'when using nested @index' do
      describe '{{#each goodbyes}}{{@index}}. {{text}}! {{#each ../goodbyes}}{{@index}} {{/each}}After {{@index}} {{/each}}{{@index}}cruel {{world}}!' do
        let(:context) { { 'goodbyes' => [{ 'text' => 'goodbye' }, { 'text' => 'Goodbye' }, { 'text' => 'GOODBYE' }], 'world' => 'world' } }
        it { should eq('0. goodbye! 0 1 2 After 0 1. Goodbye! 0 1 2 After 1 2. GOODBYE! 0 1 2 After 2 cruel world!') }
      end
    end

    context 'when using @first' do
      describe '{{#each goodbyes}}{{#if @first}}{{text}}! {{/if}}{{/each}}cruel {{world}}!' do
        let(:context) { { 'goodbyes' => [{ 'text' => 'goodbye' }, { 'text' => 'Goodbye' }, { 'text' => 'GOODBYE' }], 'world' => 'world' } }
        it { should eq('goodbye! cruel world!') }
      end
    end

    context 'when using nested @first' do
      describe '{{#each goodbyes}}({{#if @first}}{{text}}! {{/if}}{{#each ../goodbyes}}{{#if @first}}{{text}}!{{/if}}{{/each}}{{#if @first}} {{text}}!{{/if}}) {{/each}}cruel {{world}}!' do
        let(:context) { { 'goodbyes' => [{ 'text' => 'goodbye' }, { 'text' => 'Goodbye' }, { 'text' => 'GOODBYE' }], 'world' => 'world' } }
        it { should eq('(goodbye! goodbye! goodbye!) (goodbye!) (goodbye!) cruel world!') }
      end
    end

    context 'when using @last' do
      describe '{{#each goodbyes}}{{#if @last}}{{text}}! {{/if}}{{/each}}cruel {{world}}!' do
        let(:context) { { 'goodbyes' => [{ 'text' => 'goodbye' }, { 'text' => 'Goodbye' }, { 'text' => 'GOODBYE' }], 'world' => 'world' } }
        it { should eq('GOODBYE! cruel world!') }
      end
    end

    context 'when using nested @last' do
      describe '{{#each goodbyes}}({{#if @last}}{{text}}! {{/if}}{{#each ../goodbyes}}{{#if @last}}{{text}}!{{/if}}{{/each}}{{#if @last}} {{text}}!{{/if}}) {{/each}}cruel {{world}}!' do
        let(:context) { { 'goodbyes' => [{ 'text' => 'goodbye' }, { 'text' => 'Goodbye' }, { 'text' => 'GOODBYE' }], 'world' => 'world' } }
        it { should eq('(GOODBYE!) (GOODBYE!) (GOODBYE! GOODBYE! GOODBYE!) cruel world!') }
      end
    end

    context 'when accessing the global data' do
      describe '{{#each letters}}{{this}}{{detectDataInsideEach}}{{/each}}' do
        pending
      end
    end
  end

  describe '#log' do
    describe '{{log "This is a message!"}}' do
      it 'should print the given message to STDOUT' do
        io = double
        io.should_receive(:puts).with('This is a message!')
        runtime.helpers.register(:log, Tempo::StandardHelperResolver::Log.new(io))
        expect(subject).to eq('')
      end
    end
  end
end