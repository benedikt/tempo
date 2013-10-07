require 'rltk'

module Tempo
  class Lexer < RLTK::Lexer

    rule /\\\\/, :default do |output|
      [:CONTENT, '\\']
    end

    rule /\\(?={{)/, :default do |output|
      push_state :escaped
    end

    rule /{{.*?(?=\\{{|{{|\z)/m, :escaped do |output|
      pop_state
      [:CONTENT, output]
    end

    rule /.*?(?=\\{{|{{|\z)/m, :default do |output|
      [:CONTENT, output]
    end

    rule /{{>/, :default do
      push_state :expression
      :OPEN_PARTIAL
    end

    rule /{{#/, :default do
      push_state :expression
      :OPEN_BLOCK
    end

    rule /{{\//, :default do
      push_state :expression
      :OPEN_ENDBLOCK
    end

    rule /{{^/, :default do
      push_state :expression
      :OPEN_INVERSE
    end

    rule /{{\s*else/, :default do
      push_state :expression
      :OPEN_INVERSE
    end

    rule /{{\^/, :default do
      push_state :expression
      :OPEN_INVERSE
    end

    rule /{{{/, :default do
      push_state :expression
      :OPEN_UNESCAPED
    end

    rule /{{&/, :default do
      push_state :expression
      :OPEN_UNESCAPED_AMP
    end

    rule /{{!--/, :default do
      push_state :comment
    end

    rule /[\s\S]*?--}}/, :comment do |comment|
      pop_state
      [:COMMENT, comment[0..-5]]
    end

    rule /{{![^-]{2}([\s\S]*?)}}/, :default do |comment|
      [:COMMENT, comment[3..-3]]
    end

    rule /{{/, :default do
      push_state :expression
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