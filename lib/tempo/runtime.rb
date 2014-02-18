require 'tempo/environment'
require 'tempo/partial_resolver'
require 'tempo/standard_helper_resolver'
require 'tempo/visitors/interpreter'

module Tempo
  class Runtime

    def initialize
      yield self if block_given?
    end

    attr_writer :partials, :helpers

    def partials
      @partials ||= Tempo::PartialResolver.new
    end

    def helpers
      @helpers ||= Tempo::StandardHelperResolver.new
    end

    def render(template, context, options = {})
      environment = Environment.new({
        :context => context,
        :options => options
      })

      render_with_environment(template, environment)
    end

    def render_with_environment(template, environment)
      visitor = Tempo::Visitors::Interpreter.new(self, environment)
      visitor.visit(template)
    end
  end
end