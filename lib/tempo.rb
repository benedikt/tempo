require 'tempo/version'

require 'tempo/lexer'
require 'tempo/parser'
require 'tempo/runtime'
require 'tempo/context'
require 'tempo/core_ext'

module Tempo
  class << self
    attr_writer :runtime

    def runtime
      @runtime ||= Tempo::Runtime.new
    end

    def render(template, context = {})
      runtime.render(template, context)
    end
  end
end
