require 'tempo/version'

require 'tempo/lexer'
require 'tempo/nodes'
require 'tempo/parser'
require 'tempo/partial_context'
require 'tempo/helper_context'
require 'tempo/runtime'

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
