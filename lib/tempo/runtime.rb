require 'cgi'
require 'tempo/partial_resolver'
require 'tempo/standard_helper_resolver'
require 'tempo/visitors/interpreter'

module Tempo
  class Runtime

    def initialize
      yield self if block_given?
    end

    def initialize_clone(original)
      @context_stack = original.context_stack.clone
      @variables_stack = original.variables_stack.clone
    end

    attr_writer :partials, :helpers

    def partials
      @partials ||= Tempo::PartialResolver.new
    end

    def helpers
      @helpers ||= Tempo::StandardHelperResolver.new
    end

    def render(template, context, options = {})
      push_context(context)
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

    def local_context
      context_stack.last
    end

    def push_context(context)
      context_stack.push(context)
    end

    def pop_context
      context_stack.pop
    end

    def local_variables
      variables_stack.last
    end

    def push_variables(variables)
      variables_stack.push(variables)
    end

    def pop_variables
      variables_stack.pop
    end

  protected

    def visitor
      Tempo::Visitors::Interpreter.new(self)
    end

    def context_stack
      @context_stack ||= []
    end

    def variables_stack
      @variables_stack ||= []
    end
  end
end