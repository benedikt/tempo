require 'spec_helper'

describe 'blocks' do
  let(:runtime) { Tempo::Runtime.new }
  let(:input) { self.class.description }
  let(:context) { {} }

  subject { runtime.render(input, context) }

  context 'handling arrays' do
    let(:context) do
      {
        'goodbyes' => [
          { 'text' => 'goodbye' },
          { 'text' => 'Goodbye' },
          { 'text' => 'GOODBYE' }
        ],
        'world' => 'world'
      }
    end

    describe '{{#goodbyes}}{{text}}! {{/goodbyes}}cruel {{world}}!' do
      it { should eq('goodbye! Goodbye! GOODBYE! cruel world!') }
    end
  end

  context 'handling empty arrays' do
    let(:context) do
      {
        'goodbyes' => [],
        'world' => 'world'
      }
    end

    describe '{{#goodbyes}}{{text}}! {{/goodbyes}}cruel {{world}}!' do
      it { should eq('cruel world!') }
    end
  end

  context 'handling arrays with @index' do
    let(:context) do
      {
        'goodbyes' => [
          { 'text' => 'goodbye' },
          { 'text' => 'Goodbye' },
          { 'text' => 'GOODBYE' }
        ],
        'world' => 'world'
      }
    end

    describe '{{#goodbyes}}{{@index}}. {{text}}! {{/goodbyes}}cruel {{world}}!' do
      it { should eq('0. goodbye! 1. Goodbye! 2. GOODBYE! cruel world!') }
    end
  end

  context 'handling empty blocks' do
    let(:context) do
      {
        'goodbyes' => [
          { 'text' => 'goodbye' },
          { 'text' => 'Goodbye' },
          { 'text' => 'GOODBYE' }
        ],
        'world' => 'world'
      }
    end

    describe '{{#goodbyes}}{{/goodbyes}}cruel {{world}}!' do
      it { should eq('cruel world!') }
    end
  end

  context 'handling blocks with complex lookup' do
    let(:context) do
      {
        'name' => 'Alan',
        'goodbyes' => [
          { 'text' => 'goodbye' },
          { 'text' => 'Goodbye' },
          { 'text' => 'GOODBYE' }
        ]
      }
    end

    describe '{{#goodbyes}}{{text}} cruel {{../name}}! {{/goodbyes}}' do
      it { should eq('goodbye cruel Alan! Goodbye cruel Alan! GOODBYE cruel Alan! ') }
    end
  end

  context 'handling blocks with complex lookup using nested context' do
    describe '{{#goodbyes}}{{text}} cruel {{foo/../name}}! {{/goodbyes}}' do
      let(:context) do
        {
          'goodbyes' => [
            { 'text' => 'goodbye' },
            { 'text' => 'Goodbye' },
            { 'text' => 'GOODBYE' }
          ],
          'world' => 'world'
        }
      end

      it 'raises an exception' do
        expect { subject }.to raise_error
      end
    end
  end

  context 'handling blocks with deep nested complex lookup' do
    let(:context) do
      {
        'omg' => 'OMG!',
        'outer' => {
          'inner' => { 'text' => 'goodbye' }
        }
      }
    end

    describe '{{#outer}}Goodbye {{#inner}}cruel {{../../omg}}{{/inner}}{{/outer}}' do
      it { should eq('Goodbye cruel OMG!') }
    end
  end

  context 'handling inverted sections' do
    context 'with unset value' do
      describe '{{#goodbyes}}{{this}}{{/goodbyes}}{{^goodbyes}}Right On!{{/goodbyes}}' do
        it { should eq('Right On!') }
      end
    end

    context 'with false value' do
      let(:context) { { 'goodbyes' => false } }

      describe '{{#goodbyes}}{{this}}{{/goodbyes}}{{^goodbyes}}Right On!{{/goodbyes}}' do
        it { should eq('Right On!') }
      end
    end

    context 'with empty set' do
      let(:context) { { 'goodbyes' => [] } }

      describe '{{#goodbyes}}{{this}}{{/goodbyes}}{{^goodbyes}}Right On!{{/goodbyes}}' do
        it { should eq('Right On!') }
      end
    end
  end

  context 'handling inverted block sections' do
    context 'with missing value and lookup in inverse section' do
      let(:context) { { 'none' => 'No people!' } }

      describe '{{#people}}{{name}}{{^}}{{none}}{{/people}}' do
        it { should eq('No people!') }
      end
    end

    context 'with empty array and lookup in inverse section' do
      let(:context) { { 'none' => 'No people!', 'people' => [] } }

      describe '{{#people}}{{name}}{{^}}{{none}}{{/people}}' do
        it { should eq('No people!') }
      end
    end
  end
end