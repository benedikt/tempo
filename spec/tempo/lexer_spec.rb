require 'spec_helper'

describe Tempo::Lexer do

  let(:input) { self.class.description }
  let(:output) { described_class.lex(input) }
  let(:types) { output.map(&:type)}

  context 'input is a simple mustache statement' do
    describe '{{foo}}' do
      it { expect(types).to eq([:OPEN, :ID, :CLOSE, :EOS]) }
      it { expect(output[1].value).to eq('foo') }
    end
  end

  context 'input includes unescaping with &' do
    describe '{{&bar}}' do
      it { expect(types).to eq([:OPEN_UNESCAPED_AMP, :ID, :CLOSE, :EOS]) }
      it { expect(output[1].value).to eq('bar') }
    end
  end

  context 'input includes unescaping with {{{' do
    describe '{{{bar}}}' do
      it { expect(types).to eq([:OPEN_UNESCAPED, :ID, :CLOSE_UNESCAPED, :EOS]) }
      it { expect(output[1].value).to eq('bar') }
    end
  end

  context 'input includes escaped delimiters' do
    describe '{{foo}} \{{bar}} {{baz}}' do
      it { expect(types).to eq([:OPEN, :ID, :CLOSE, :CONTENT, :CONTENT, :OPEN, :ID, :CLOSE, :EOS]) }
      it { expect(output[4].value).to eq('{{bar}} ') }
    end
  end

  context 'input includes multiple escaped delimiters' do
    describe '{{foo}} \{{bar}} \{{baz}}' do
      it { expect(types).to eq([:OPEN, :ID, :CLOSE, :CONTENT, :CONTENT, :CONTENT, :EOS]) }
      it { expect(output[3].value).to eq(' ') }
      it { expect(output[4].value).to eq('{{bar}} ') }
      it { expect(output[5].value).to eq('{{baz}}') }
    end
  end

  context 'input includes escaped triple stash statements' do
    describe '{{foo}} \{{{bar}}} {{baz}}' do
      it { expect(types).to eq([:OPEN, :ID, :CLOSE, :CONTENT, :CONTENT, :OPEN, :ID, :CLOSE, :EOS]) }
      it { expect(output[4].value).to eq('{{{bar}}} ') }
    end
  end

  context 'input includes escaped slash before statement' do
    describe '\\\\{{foo}}' do
      it { expect(types).to eq([:CONTENT, :OPEN, :ID, :CLOSE, :EOS]) }
      it { expect(output[0].value).to eq('\\') }
      it { expect(output[2].value).to eq('foo') }
    end

    describe '\\\\ {{foo}}' do
      it { expect(types).to eq([:CONTENT, :OPEN, :ID, :CLOSE, :EOS]) }
      it { expect(output[0].value).to eq('\\\\ ') }
      it { expect(output[2].value).to eq('foo') }
    end
  end

  context 'input includes escaped escape characters' do
    describe '{{foo}} \\\\{{bar}} {{baz}}' do
      it { expect(types).to eq([:OPEN, :ID, :CLOSE, :CONTENT, :OPEN, :ID, :CLOSE, :CONTENT, :OPEN, :ID, :CLOSE, :EOS]) }
      it { expect(output[3].value).to eq(' \\') }
      it { expect(output[5].value).to eq('bar') }
    end
  end

  context 'input includes multiple escaped escaped characters' do
    describe '{{foo}} \\\\{{bar}} \\\\{{baz}}' do
      it { expect(types).to eq([:OPEN, :ID, :CLOSE, :CONTENT, :OPEN, :ID, :CLOSE, :CONTENT, :OPEN, :ID, :CLOSE, :EOS]) }
      it { expect(output[3].value).to eq(' \\') }
      it { expect(output[5].value).to eq('bar') }
      it { expect(output[7].value).to eq(' \\') }
      it { expect(output[9].value).to eq('baz') }
    end
  end

  context 'input includes mixed escaped delimiters and escaped escape characters' do
    describe '{{foo}} \\\\{{bar}} \\{{baz}}' do
      it { expect(types).to eq([:OPEN, :ID, :CLOSE, :CONTENT, :OPEN, :ID, :CLOSE, :CONTENT, :CONTENT, :EOS]) }
      it { expect(output[1].value).to eq('foo') }
      it { expect(output[3].value).to eq(' \\') }
      it { expect(output[5].value).to eq('bar') }
      it { expect(output[7].value).to eq(' ') }
      it { expect(output[8].value).to eq('{{baz}}') }
    end
  end

  context 'input includes escaped escape character on a triple stash' do
    describe '{{foo}} \\\\{{{bar}}} {{baz}}' do
      it { expect(types).to eq([:OPEN, :ID, :CLOSE, :CONTENT, :OPEN_UNESCAPED, :ID, :CLOSE_UNESCAPED, :CONTENT, :OPEN, :ID, :CLOSE, :EOS]) }
      it { expect(output[3].value).to eq(' \\') }
      it { expect(output[5].value).to eq('bar') }
    end
  end

  context 'input includes a path notation' do
    describe '{{foo/bar}}' do
      it { expect(types).to eq([:OPEN, :ID, :SEP, :ID, :CLOSE, :EOS]) }
      it { expect(output[1].value).to eq('foo') }
      it { expect(output[2].value).to eq('/') }
      it { expect(output[3].value).to eq('bar') }
    end
  end

  context 'input includes a dot notiation' do
    describe '{{foo.bar}}' do
      it { expect(types).to eq([:OPEN, :ID, :SEP, :ID, :CLOSE, :EOS]) }
      it { expect(output[1].value).to eq('foo') }
      it { expect(output[2].value).to eq('.') }
      it { expect(output[3].value).to eq('bar') }
    end

    describe '{{foo.bar.baz}}' do
      it { expect(types).to eq([:OPEN, :ID, :SEP, :ID, :SEP, :ID, :CLOSE, :EOS]) }
      it { expect(output[1].value).to eq('foo') }
      it { expect(output[3].value).to eq('bar') }
      it { expect(output[5].value).to eq('baz') }
    end
  end

  context 'input includes path literals with []' do
    describe '{{foo.[bar]}}' do
      it { expect(types).to eq([:OPEN, :ID, :SEP, :ID, :CLOSE, :EOS]) }
      it { expect(output[1].value).to eq('foo') }
      it { expect(output[3].value).to eq('bar') }
    end
  end

  context 'input includes multiple path literals with [] on a line' do
    describe '{{foo.[bar]}}{{foo.[baz]}}' do
      it { expect(types).to eq([:OPEN, :ID, :SEP, :ID, :CLOSE, :OPEN, :ID, :SEP, :ID, :CLOSE, :EOS]) }
    end
  end

  context 'input includes a single . as identifier' do
    describe '{{.}}' do
      it { expect(types).to eq([:OPEN, :ID, :CLOSE, :EOS]) }
      it { expect(output[1].value).to eq('.') }

    end
  end

  context 'input includes a relative path' do
    describe '{{../foo/bar}}' do
      it { expect(types).to eq([:OPEN, :ID, :SEP, :ID, :SEP, :ID, :CLOSE, :EOS]) }
      it { expect(output[1].value).to eq('..') }
    end
  end

  context 'input includes a statement with spaces' do
    describe '{{  foo  }}' do
      it { expect(types).to eq([:OPEN, :ID, :CLOSE, :EOS]) }
      it { expect(output[1].value).to eq('foo') }
    end
  end

  context 'input includes a statement with line breaks' do
    describe "{{  foo  \n  bar }}" do
      it { expect(types).to eq([:OPEN, :ID, :ID, :CLOSE, :EOS]) }
      it { expect(output[1].value).to eq('foo') }
      it { expect(output[2].value).to eq('bar') }
    end
  end

  context 'input includes raw content' do
    describe "foo {{bar}} baz" do
      it { expect(types).to eq([:CONTENT, :OPEN, :ID, :CLOSE, :CONTENT, :EOS]) }
      it { expect(output[0].value).to eq('foo ') }
      it { expect(output[4].value).to eq(' baz') }
    end
  end

  context 'input includes a partial statement' do
    describe "{{> foo}}" do
      it { expect(types).to eq([:OPEN_PARTIAL, :ID, :CLOSE, :EOS]) }
      it { expect(output[1].value).to eq('foo') }
    end
  end

  context 'input includes a partial statement with context' do
    describe "{{> foo bar}}" do
      it { expect(types).to eq([:OPEN_PARTIAL, :ID, :ID, :CLOSE, :EOS]) }
      it { expect(output[1].value).to eq('foo') }
      it { expect(output[2].value).to eq('bar') }
    end
  end

  context 'input includes a inline comment' do
    describe 'foo {{! this is a comment }} bar {{ baz }}' do
      it { expect(types).to eq([:CONTENT, :COMMENT, :CONTENT, :OPEN, :ID, :CLOSE, :EOS]) }
      it { expect(output[1].value).to eq(' this is a comment ') }
    end
  end

  context 'input includes a block comment' do
    describe 'foo {{!-- this is a {{comment}} --}} bar {{baz}}' do
      it { expect(types).to eq([:CONTENT, :COMMENT, :CONTENT, :OPEN, :ID, :CLOSE, :EOS]) }
      it { expect(output[1].value).to eq(' this is a {{comment}} ') }
      it { expect(output[2].value).to eq(' bar ') }
      it { expect(output[4].value).to eq('baz') }
    end
  end

  context 'input includes a block comment with line breaks' do
    describe "foo {{!-- this is a\n{{comment}}\n--}} bar {{baz}}" do
      it { expect(types).to eq([:CONTENT, :COMMENT, :CONTENT, :OPEN, :ID, :CLOSE, :EOS]) }
      it { expect(output[1].value).to eq(" this is a\n{{comment}}\n") }
    end
  end

  context 'input includes a block statement' do
    describe '{{#foo}}content{{/foo}}' do
      it { expect(types).to eq([:OPEN_BLOCK, :ID, :CLOSE, :CONTENT, :OPEN_ENDBLOCK, :ID, :CLOSE, :EOS]) }
    end
  end

  context 'input includes an inverse statement' do
    describe '{{^}}' do
      it { expect(types).to eq([:OPEN_INVERSE, :CLOSE, :EOS]) }
    end

    describe '{{else}}' do
      it { expect(types).to eq([:OPEN_INVERSE, :CLOSE, :EOS]) }
    end

    describe '{{  else  }}' do
      it { expect(types).to eq([:OPEN_INVERSE, :CLOSE, :EOS]) }
    end
  end

  context 'input includes an inverse statement with identifier' do
    describe '{{^foo}}' do
      it { expect(types).to eq([:OPEN_INVERSE, :ID, :CLOSE, :EOS]) }
      it { expect(output[1].value).to eq('foo') }
    end

    describe '{{^   foo   }}' do
      it { expect(types).to eq([:OPEN_INVERSE, :ID, :CLOSE, :EOS]) }
      it { expect(output[1].value).to eq('foo') }
    end
  end

  context 'input includes a statement with parameters' do
    describe '{{foo bar baz}}' do
      it { expect(types).to eq([:OPEN, :ID, :ID, :ID, :CLOSE, :EOS]) }
      it { expect(output[1].value).to eq('foo') }
      it { expect(output[2].value).to eq('bar') }
      it { expect(output[3].value).to eq('baz') }
    end
  end

  context 'input includes a statement with params including a string' do
    describe '{{foo bar "baz"}}' do
      it { expect(types).to eq([:OPEN, :ID, :ID, :STRING, :CLOSE, :EOS]) }
      it { expect(output[1].value).to eq('foo') }
      it { expect(output[2].value).to eq('bar') }
      it { expect(output[3].value).to eq('baz') }
    end

    describe "{{foo bar 'baz'}}" do
      it { expect(types).to eq([:OPEN, :ID, :ID, :STRING, :CLOSE, :EOS]) }
      it { expect(output[1].value).to eq('foo') }
      it { expect(output[2].value).to eq('bar') }
      it { expect(output[3].value).to eq('baz') }
    end
  end

  context 'input includes a statement with params including a string with spaces' do
    describe '{{foo "bar baz"}}' do
      it { expect(types).to eq([:OPEN, :ID, :STRING, :CLOSE, :EOS]) }
      it { expect(output[1].value).to eq('foo') }
      it { expect(output[2].value).to eq('bar baz') }
    end
  end

  context 'input includes a statement with params including a string with escaped quotes' do
    describe '{{foo "bar\"baz"}}' do
      it { expect(types).to eq([:OPEN, :ID, :STRING, :CLOSE, :EOS]) }
      it { expect(output[1].value).to eq('foo') }
      it { expect(output[2].value).to eq('bar"baz') }
    end

    describe "{{foo 'bar\\'baz'}}" do
      it { expect(types).to eq([:OPEN, :ID, :STRING, :CLOSE, :EOS]) }
      it { expect(output[1].value).to eq('foo') }
      it { expect(output[2].value).to eq("bar'baz") }
    end
  end

  context 'input includes a statement with params including a number' do
    describe '{{foo 1}}' do
      it { expect(types).to eq([:OPEN, :ID, :NUMBER, :CLOSE, :EOS]) }
      it { expect(output[1].value).to eq('foo') }
      it { expect(output[2].value).to eq('1') }
    end

    describe '{{foo -1}}' do
      it { expect(types).to eq([:OPEN, :ID, :NUMBER, :CLOSE, :EOS]) }
      it { expect(output[1].value).to eq('foo') }
      it { expect(output[2].value).to eq('-1') }
    end
  end

  context 'input includes a statement with params including a boolean' do
    describe '{{foo true}}' do
      it { expect(types).to eq([:OPEN, :ID, :BOOLEAN, :CLOSE, :EOS]) }
      it { expect(output[1].value).to eq('foo') }
      it { expect(output[2].value).to eq('true') }
    end

    describe '{{foo false}}' do
      it { expect(types).to eq([:OPEN, :ID, :BOOLEAN, :CLOSE, :EOS]) }
      it { expect(output[1].value).to eq('foo') }
      it { expect(output[2].value).to eq('false') }
    end
  end

  context 'input includes a statement with hash arguments' do
    describe '{{foo bar=baz}}' do
      it { expect(types).to eq([:OPEN, :ID, :ID, :EQUALS, :ID, :CLOSE, :EOS]) }
      it { expect(output[1].value).to eq('foo') }
      it { expect(output[2].value).to eq('bar') }
      it { expect(output[4].value).to eq('baz') }
    end

    describe '{{foo bar baz=bat}}' do
      it { expect(types).to eq([:OPEN, :ID, :ID, :ID, :EQUALS, :ID, :CLOSE, :EOS]) }
      it { expect(output[1].value).to eq('foo') }
      it { expect(output[2].value).to eq('bar') }
      it { expect(output[3].value).to eq('baz') }
      it { expect(output[5].value).to eq('bat') }
    end

    describe "{{foo bar\n baz=bat}}" do
      it { expect(types).to eq([:OPEN, :ID, :ID, :ID, :EQUALS, :ID, :CLOSE, :EOS]) }
      it { expect(output[1].value).to eq('foo') }
      it { expect(output[2].value).to eq('bar') }
      it { expect(output[3].value).to eq('baz') }
      it { expect(output[5].value).to eq('bat') }
    end

    describe '{{foo bar baz=1}}' do
      it { expect(types).to eq([:OPEN, :ID, :ID, :ID, :EQUALS, :NUMBER, :CLOSE, :EOS]) }
      it { expect(output[1].value).to eq('foo') }
      it { expect(output[2].value).to eq('bar') }
      it { expect(output[3].value).to eq('baz') }
      it { expect(output[5].value).to eq('1') }
    end

    describe '{{foo bar baz=true}}' do
      it { expect(types).to eq([:OPEN, :ID, :ID, :ID, :EQUALS, :BOOLEAN, :CLOSE, :EOS]) }
      it { expect(output[1].value).to eq('foo') }
      it { expect(output[2].value).to eq('bar') }
      it { expect(output[3].value).to eq('baz') }
      it { expect(output[5].value).to eq('true') }
    end

    describe '{{foo bar baz=false}}' do
      it { expect(types).to eq([:OPEN, :ID, :ID, :ID, :EQUALS, :BOOLEAN, :CLOSE, :EOS]) }
      it { expect(output[1].value).to eq('foo') }
      it { expect(output[2].value).to eq('bar') }
      it { expect(output[3].value).to eq('baz') }
      it { expect(output[5].value).to eq('false') }
    end

    describe '{{foo bar baz="bat"}}' do
      it { expect(types).to eq([:OPEN, :ID, :ID, :ID, :EQUALS, :STRING, :CLOSE, :EOS]) }
      it { expect(output[1].value).to eq('foo') }
      it { expect(output[2].value).to eq('bar') }
      it { expect(output[3].value).to eq('baz') }
      it { expect(output[5].value).to eq('bat') }
    end

    describe "{{foo bar baz='bat'}}" do
      it { expect(types).to eq([:OPEN, :ID, :ID, :ID, :EQUALS, :STRING, :CLOSE, :EOS]) }
      it { expect(output[1].value).to eq('foo') }
      it { expect(output[2].value).to eq('bar') }
      it { expect(output[3].value).to eq('baz') }
      it { expect(output[5].value).to eq('bat') }
    end

    describe '{{foo bar baz="bat" bam=wot}}' do
      it { expect(types).to eq([:OPEN, :ID, :ID, :ID, :EQUALS, :STRING, :ID, :EQUALS, :ID, :CLOSE, :EOS]) }
      it { expect(output[1].value).to eq('foo') }
      it { expect(output[2].value).to eq('bar') }
      it { expect(output[3].value).to eq('baz') }
      it { expect(output[5].value).to eq('bat') }
      it { expect(output[6].value).to eq('bam') }
      it { expect(output[8].value).to eq('wot') }
    end

    describe '{{foo omg bar=baz bat="bam"}}' do
      it { expect(types).to eq([:OPEN, :ID, :ID, :ID, :EQUALS, :ID, :ID, :EQUALS, :STRING, :CLOSE, :EOS]) }
      it { expect(output[1].value).to eq('foo') }
      it { expect(output[2].value).to eq('omg') }
      it { expect(output[3].value).to eq('bar') }
      it { expect(output[5].value).to eq('baz') }
      it { expect(output[6].value).to eq('bat') }
      it { expect(output[8].value).to eq('bam') }
    end
  end

  context 'input includes a special @ identifier' do
    describe '{{@foo}}' do
      it { expect(types).to eq([:OPEN, :DATA, :ID, :CLOSE, :EOS]) }
      it { expect(output[2].value).to eq('foo') }
    end

    describe '{{foo @bar}}' do
      it { expect(types).to eq([:OPEN, :ID, :DATA, :ID, :CLOSE, :EOS]) }
      it { expect(output[3].value).to eq('bar') }
    end

    describe '{{foo bar=@baz}}' do
      it { expect(types).to eq([:OPEN, :ID, :ID, :EQUALS, :DATA, :ID, :CLOSE, :EOS]) }
      it { expect(output[2].value).to eq('bar') }
      it { expect(output[5].value).to eq('baz') }
    end
  end

  context 'input with broken statements' do
    describe '{{foo}' do
      it { expect { types }.to raise_error }
    end

    describe '{{foo & }}' do
      it { expect { types }.to raise_error }
    end
  end
end