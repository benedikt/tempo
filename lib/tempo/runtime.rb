require 'cgi'
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

      visitor = Tempo::Visitors::Interpreter.new(self, environment)
      visitor.visit(template)
    end

    def escape(output)
      return output if output.kind_of?(Tempo::SafeString)

      CGI.escapeHTML(output).gsub(/(['`])/, {
        "'" => '&#39;',
        '`' => '&#x60;'
      })
    end

    def lookup_helper(node)
      if node.kind_of?(Nodes::CallNode) && node.ids.size == 1
        helpers.lookup(node.ids.first)
      else
        helpers.lookup(node)
      end
    end

  end
end