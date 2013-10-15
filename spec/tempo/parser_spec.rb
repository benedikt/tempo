require 'spec_helper'

describe Tempo::Parser do

  let(:input) { Tempo::Lexer.lex(self.class.description) }
  let(:ast) { described_class.parse(input).to_s }

  context 'input is a simple statement' do
    describe '{{foo}}' do
      it { expect(ast).to eq('EXPRESSION(ID(foo) [] )') }
    end

    describe '{{foo?}}' do
      it { expect(ast).to eq('EXPRESSION(ID(foo?) [] )') }
    end

    describe '{{foo_}}' do
      it { expect(ast).to eq('EXPRESSION(ID(foo_) [] )') }
    end

    describe '{{foo-}}' do
      it { expect(ast).to eq('EXPRESSION(ID(foo-) [] )') }
    end

    describe '{{foo:}}' do
      it { expect(ast).to eq('EXPRESSION(ID(foo:) [] )') }
    end
  end

  context 'input is a simple data statement' do
    describe '{{@foo}}' do
      it { expect(ast).to eq('EXPRESSION(DATA(foo) [] )') }
    end
  end

  context 'input is a path statement' do
    describe '{{foo/bar}}' do
      it { expect(ast).to eq('EXPRESSION(PATH(ID(foo) ID(bar)) [] )') }
    end
  end

  context 'input is a path statement with this' do
    describe '{{this/foo}}' do
      it { expect(ast).to eq('EXPRESSION(ID(foo) [] )') }
    end
  end

  context 'input is a unescaped expression' do
    describe '{{{foo}}}' do
      it { expect(ast).to eq('UNESCAPED_EXPRESSION(ID(foo) [] )')}
    end

    describe '{{&foo}}' do
      it { expect(ast).to eq('UNESCAPED_EXPRESSION(ID(foo) [] )')}
    end
  end

  context 'input is a statement with parameters' do
    describe '{{foo bar}}' do
      it { expect(ast).to eq('EXPRESSION(ID(foo) [ID(bar)] )')}
    end

    describe '{{foo bar "baz"}}' do
      it { expect(ast).to eq('EXPRESSION(ID(foo) [ID(bar) STRING("baz")] )')}
    end

    describe '{{foo bar 1}}' do
      it { expect(ast).to eq('EXPRESSION(ID(foo) [ID(bar) NUMBER(1)] )')}
    end

    describe '{{foo bar true}}' do
      it { expect(ast).to eq('EXPRESSION(ID(foo) [ID(bar) BOOLEAN(true)] )')}
    end

    describe '{{foo @bar}}' do
      it { expect(ast).to eq('EXPRESSION(ID(foo) [DATA(bar)] )') }
    end
  end

  context 'input is a statement with hash arguments' do
    describe '{{foo bar=baz}}' do
      it { expect(ast).to eq('EXPRESSION(ID(foo) [] {bar=ID(baz)})')}
    end

    describe '{{foo bar=1}}' do
      it { expect(ast).to eq('EXPRESSION(ID(foo) [] {bar=NUMBER(1)})')}
    end

    describe '{{foo bar=true}}' do
      it { expect(ast).to eq('EXPRESSION(ID(foo) [] {bar=BOOLEAN(true)})')}
    end

    describe '{{foo bar=false}}' do
      it { expect(ast).to eq('EXPRESSION(ID(foo) [] {bar=BOOLEAN(false)})')}
    end

    describe '{{foo bar=@baz}}' do
      it { expect(ast).to eq('EXPRESSION(ID(foo) [] {bar=DATA(baz)})')}
    end

    describe '{{foo bar="baz"}}' do
      it { expect(ast).to eq('EXPRESSION(ID(foo) [] {bar=STRING("baz")})')}
    end

    describe '{{foo bar=baz bat=bam}}' do
      it { expect(ast).to eq('EXPRESSION(ID(foo) [] {bar=ID(baz) bat=ID(bam)})')}
    end

    describe '{{foo bar=baz bat="bam"}}' do
      it { expect(ast).to eq('EXPRESSION(ID(foo) [] {bar=ID(baz) bat=STRING("bam")})')}
    end
  end

  context 'input is a statement with both parameters and has arguments' do
    describe '{{foo omg bar=baz bat="bam"}}' do
      it { expect(ast).to eq('EXPRESSION(ID(foo) [ID(omg)] {bar=ID(baz) bat=STRING("bam")})')}
    end

    describe '{{foo omg bar=baz bat="bam" baz=1}}' do
      it { expect(ast).to eq('EXPRESSION(ID(foo) [ID(omg)] {bar=ID(baz) bat=STRING("bam") baz=NUMBER(1)})')}
    end

    describe '{{foo omg bar=baz bat="bam" baz=true}}' do
      it { expect(ast).to eq('EXPRESSION(ID(foo) [ID(omg)] {bar=ID(baz) bat=STRING("bam") baz=BOOLEAN(true)})')}
    end

    describe '{{foo omg bar=baz bat="bam" baz=false}}' do
      it { expect(ast).to eq('EXPRESSION(ID(foo) [ID(omg)] {bar=ID(baz) bat=STRING("bam") baz=BOOLEAN(false)})')}
    end
  end

  context 'input contains raw content and a statement' do
    describe 'foo bar {{baz}}' do
      it { expect(ast).to eq('CONTENT("foo bar ") EXPRESSION(ID(baz) [] )')}
    end
  end

  context 'input contains a partial statement' do
    describe '{{> foo}}' do
      it { expect(ast).to eq('PARTIAL(foo )') }
    end
  end

  context 'input contains a partial with context' do
    describe '{{> foo bar}}' do
      it { expect(ast).to eq('PARTIAL(foo ID(bar))')}
    end
  end

  context 'input contains a partial with a complex name' do
    describe '{{> shared/partial?.bar}}' do
      it { expect(ast).to eq('PARTIAL(shared/partial?.bar )') }
    end
  end

  context 'input contains a comment' do
    describe '{{! this is a comment }}' do
      it { expect(ast).to eq('COMMENT(" this is a comment ")') }
    end
  end

  context 'input contains a multi-line comment' do
    describe "{{!\nthis is a comment\n}}"do
      it { expect(ast).to eq('COMMENT("\nthis is a comment\n")') }
    end
  end

  context 'input includes a block with an inverse section' do
    describe '{{#foo}} bar {{^}} baz {{/foo}}' do
      it { expect(ast).to eq('BLOCK(ID(foo) []  TEMPLATE(CONTENT(" bar ")) INVERSE(CONTENT(" baz ")))') }
    end

    describe '{{#foo}} bar {{else}} baz {{/foo}}', :debug => true do
      it { expect(ast).to eq('BLOCK(ID(foo) []  TEMPLATE(CONTENT(" bar ")) INVERSE(CONTENT(" baz ")))') }
    end
  end

  context 'input includes an empty block' do
    describe '{{#foo}}{{/foo}}' do
      it { expect(ast).to eq('BLOCK(ID(foo) []  TEMPLATE() INVERSE())') }
    end
  end

  context 'input containts an empty block and an empty inverse' do
    describe '{{#foo}}{{^}}{{/foo}}' do
      it { expect(ast).to eq('BLOCK(ID(foo) []  TEMPLATE() INVERSE())') }
    end

    describe '{{#foo}}{{else}}{{/foo}}' do
      it { expect(ast).to eq('BLOCK(ID(foo) []  TEMPLATE() INVERSE())') }
    end
  end

  context 'input containts a non-empty block and an empty inverse' do
    describe '{{#foo}} bar {{^}}{{/foo}}' do
      it { expect(ast).to eq('BLOCK(ID(foo) []  TEMPLATE(CONTENT(" bar ")) INVERSE())') }
    end

    describe '{{#foo}} bar {{else}}{{/foo}}' do
      it { expect(ast).to eq('BLOCK(ID(foo) []  TEMPLATE(CONTENT(" bar ")) INVERSE())') }
    end
  end

  context 'input containts an empty block and a non-empty inverse' do
    describe '{{#foo}}{{^}} bar {{/foo}}' do
      it { expect(ast).to eq('BLOCK(ID(foo) []  TEMPLATE() INVERSE(CONTENT(" bar ")))') }
    end

    describe '{{#foo}}{{else}} bar {{/foo}}' do
      it { expect(ast).to eq('BLOCK(ID(foo) []  TEMPLATE() INVERSE(CONTENT(" bar ")))') }
    end
  end

  context 'input contains a standalone inverse section' do
    describe '{{^foo}} bar {{/foo}}' do
      it { expect(ast).to eq('BLOCK(ID(foo) []  TEMPLATE() INVERSE(CONTENT(" bar ")))')}
    end
  end

  context 'input includes a block helper with a path parameter' do
    describe '{{foo bar.baz.bam}}' do
      it { expect(ast).to eq('EXPRESSION(ID(foo) [PATH(ID(bar) ID(baz) ID(bam))] )')}
    end

    describe '{{#foo bar.baz.bam}}{{/foo}}' do
      it { expect(ast).to eq('BLOCK(ID(foo) [PATH(ID(bar) ID(baz) ID(bam))]  TEMPLATE() INVERSE())')}
    end
  end

  context 'input with invalid language' do
    describe 'foo{{^}}bar' do
      it { expect { ast }.to raise_error }
    end

    describe '{{foo}' do
      it { expect { ast }.to raise_error }
    end

    describe '{{foo &}' do
      it { expect { ast }.to raise_error }
    end

    describe '{{#goodbyes}}{{/hellos}}' do
      it { expect { ast }.to raise_error }
    end
  end
end
