require 'cgi'
require 'tempo/partial_resolver'
require 'tempo/standard_helper_resolver'

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

    def render(template, context)
      environment = Environment.new
      environment.push_context(context)
      visit(template, environment)
    end

  private

    def visit(node, environment)
      send("visit_#{node.class.name.split('::').last}", node, environment)
    end

    def visit_String(node, environment)
      template = Parser.parse(Lexer.lex(node))
      visit(template, environment)
    end

    def visit_TemplateNode(node, environment)
      node.statements.each_with_object('') do |statement, output|
        output << visit(statement, environment)
      end
    end

    def visit_ContentNode(node, environment)
      node.value
    end

    def visit_UnescapedExpressionNode(node, environment)
      arguments = node.params.map { |p| visit(p, environment) }
      options = node.hash && visit(node.hash, environment) || {}

      if helper = lookup_helper(node.path)
        helper.call(*arguments, options)
      else
        visit(node.path, environment)
      end.to_s
    end

    def visit_ExpressionNode(node, environment)
      escape(visit_UnescapedExpressionNode(node, environment))
    end

    def visit_CallNode(node, environment)
      env = environment.clone

      parent_allowed = true
      node.ids.each_with_index.inject(environment.local_context) do |ctx, (segment, index)|
        if segment == 'this' || segment == '.'
          parent_allowed = false

          if index == 0
            ctx.to_tempo_context
          else
            raise "Nested this is not allowed"
          end
        elsif segment == '..'
          raise "Nested parent call is not allowed" unless parent_allowed
          env.pop_context
          env.local_context.to_tempo_context
        elsif index == 0 && helper = helpers.lookup(segment)
          parent_allowed = false
          helper.call
        else
          parent_allowed = false
          ctx = ctx.to_tempo_context
          ctx && ctx.invoke(segment)
        end
      end
    end

    def visit_CommentNode(node, environment)
      ''
    end

    def visit_BlockExpressionNode(node, environment)
      arguments = node.params.map { |p| visit(p, environment) }
      options = node.hash && visit(node.hash, environment) || {}

      conditional = if helper = lookup_helper(node.path)
        helper
      else
        visit(node.path, environment)
      end

      if conditional.respond_to?(:call)
        conditional.call(*arguments, options) do |variant, local_context, local_variables|
          variant, local_context, local_variables, = :template, variant, local_context unless variant.kind_of?(Symbol)

          environment.push_variables(local_variables)
          environment.push_context(local_context) if local_context
          result = visit(node.send(variant), environment)
          environment.pop_context if local_context
          environment.pop_variables
          result
        end.to_s
      elsif !conditional.kind_of?(HashContext) && conditional.respond_to?(:each) && conditional.enum_for(:each).count > 0
        conditional.enum_for(:each).each_with_index.inject('') do |output, (child, index)|
          environment.push_variables({ 'index' => index })
          environment.push_context(child)
          output << visit(node.template, environment)
          environment.pop_context
          environment.pop_variables
          output
        end
      elsif conditional && !(conditional.respond_to?(:empty?) && conditional.empty?)
        environment.push_context(conditional)
        result = visit(node.template, environment)
        environment.pop_context
        result
      else
        result = visit(node.inverse, environment)
        result
      end
    end

    def visit_NilClass(node, environment)
      ''
    end

    def visit_BooleanNode(node, environment)
      node.value === 'true'
    end

    def visit_NumberNode(node, environment)
      node.value.to_i
    end

    def visit_StringNode(node, environment)
      node.value
    end

    def visit_PartialNode(node, environment)
      partial = partials.lookup(node.name)

      if partial
        environment.push_context(visit(node.context_id, environment)) if node.context_id
        result = visit(partial, environment)
        environment.pop_context if node.context_id
        result
      else
        "Missing partial '#{node.name}'"
      end
    end

    def visit_HashNode(node, environment)
      node.pairs.each_with_object({}) do |(key, value), output|
        output[key] = visit(value, environment)
      end
    end

    def visit_DataNode(node, environment)
      return '' unless local_variables = environment.local_variables
      local_variables[node.id.to_s]
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
      end
    end

    class Environment

      def initialize_clone(original)
        @context_stack = original.context_stack.clone
        @variables_stack = original.variables_stack.clone
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

      def context_stack
        @context_stack ||= []
      end

      def variables_stack
        @variables_stack ||= []
      end

    end

  end
end