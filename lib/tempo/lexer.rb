require 'rltk'

module Tempo
  class Lexer < RLTK::Lexer

    rule /.*?(?={{)/, :default do |output|
      if output[-2..-1] == '\\\\'
        output = output[0..-2]
        push_state :expression
      elsif output[-1] == '\\'
        output = output[0..-2]
        push_state :escaped
      else
        push_state :expression
      end

      [:CONTENT, output] unless output.empty?
    end

    rule /\\(?={{)/, :default do |output|
      push_state :escaped
    end

    rule /{{.*?(?={{|\z)/m, :escaped do |output|
      if output[-1] == '\\'
        output = output[0..-2]
      else
        pop_state
      end

      [:CONTENT, output]
    end

    rule /.*?(?=\\{{|{{|\z)/m, :default do |output|
      [:CONTENT, output]
    end

    rule /{{>/, :expression do
      :OPEN_PARTIAL
    end

    rule /{{#/, :expression do
      :OPEN_BLOCK
    end

    rule /{{\//, :expression do
      :OPEN_ENDBLOCK
    end

    rule /{{^/, :expression do
      :OPEN_INVERSE
    end

    rule /{{\s*else/, :expression do
      :OPEN_INVERSE
    end

    rule /{{\^/, :expression do
      :OPEN_INVERSE
    end

    rule /{{{/, :expression do
      :OPEN_UNESCAPED
    end

    rule /{{&/, :expression do
      :OPEN_UNESCAPED_AMP
    end

    rule /{{!--/, :expression do
      push_state :comment
    end

    rule /[\s\S]*?--}}/, :comment do |comment|
      pop_state
      pop_state
      [:COMMENT, comment[0..-5]]
    end

    rule /{{![^-]{2}([\s\S]*?)}}/, :expression do |comment|
      pop_state
      [:COMMENT, comment[3..-3]]
    end

    rule /{{/, :expression do
      :OPEN
    end

    rule /\s+/, :expression do
      # Ignore whitespace
    end

    rule /"(\\["]|[^"])*"/, :expression do |string|
      [:STRING, string[1..-2].gsub(/\\"/, '"')]
    end

    rule /'(\\[']|[^'])*'/, :expression do |string|
      [:STRING, string[1..-2].gsub(/\\'/, "'")]
    end

    rule /\-?[0-9]+/, :expression do |number|
      [:NUMBER, number]
    end

    rule /(true|false)/, :expression do |boolean|
      [:BOOLEAN, boolean]
    end

    rule /[^\s!"#%-,\.\/;->@\[-\^`\{-~]+(?=[=}\s\/.])/, :expression do |name|
      [:ID, name]
    end

    rule /\[[^\s!"#%-,\.\/;->@\[-\^`\{-~]+\]/, :expression do |name|
      [:ID, name[1..-2]]
    end

    rule /[.]{1,2}(?=[}|\/])/, :expression do |name|
      [:ID, name]
    end

    rule /\.|\//, :expression do |separator|
      [:SEP, separator]
    end

    rule /\=/, :expression do
      :EQUALS
    end

    rule /@/, :expression do
      :DATA
    end

    rule /}}}/, :expression do
      pop_state
      :CLOSE_UNESCAPED
    end

    rule /}}/, :expression do
      pop_state
      :CLOSE
    end

  end
end