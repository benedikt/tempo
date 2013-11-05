require 'cgi'
require 'tempo/partial_resolver'
require 'tempo/standard_helper_context'

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
      @helpers ||= Tempo::StandardHelperContext.new
    end

    def render(template, context)
      visit(template, context)
    end

  private

    def visit(node, context)
      send("visit_#{node.class.name.split('::').last}", node, context)
    end

    def visit_String(node, context)
      template = Parser.parse(Lexer.lex(node))
      visit(template, context)
    end

    def visit_TemplateNode(node, context)
      node.statements.each_with_object('') do |statement, output|
        output << visit(statement, context)
      end
    end

    def visit_ContentNode(node, context)
      node.value
    end

    def visit_UnescapedExpressionNode(node, context)
      arguments = node.params.map { |p| visit(p, context) }
      options = node.hash && visit(node.hash, context) || {}

      if node.path.kind_of?(Nodes::CallNode) && helper = helpers.lookup(node.path.id)
        helper.call(*arguments, options)
      else
        visit(node.path, context)
      end.to_s
    end

    def visit_ExpressionNode(node, context)
      escape(visit_UnescapedExpressionNode(node, context))
    end

    def visit_CallNode(node, context)
      context = context.to_tempo_context
      context && context.invoke(node.id)
    end

    def visit_PathNode(node, context)
      node.ids.each_with_index.inject(context) do |ctx, (segment, index)|
        if index == 0 && helper = helpers.lookup(segment.id)
          helper.call
        else
          visit(segment, ctx)
        end
      end
    end

    def visit_CommentNode(node, context)
      ''
    end

    def visit_BlockExpressionNode(node, context)
      arguments = node.params.map { |p| visit(p, context) }
      options = node.hash && visit(node.hash, context) || {}

      conditional = if node.path.kind_of?(Nodes::CallNode) && helper = helpers.lookup(node.path.id)
        helper
      else
        visit(node.path, context)
      end

      if conditional.respond_to?(:call)
        conditional.call(*arguments, options) do |variant, local_context, local_variables|
          variant, local_context, local_variables, = :template, variant, local_context unless variant.kind_of?(Symbol)

          local_variables_stack.push(local_variables)
          result = visit(node.send(variant), local_context || context)
          local_variables_stack.pop
          result
        end.to_s
      elsif conditional.respond_to?(:each) && conditional.enum_for(:each).count > 0
        conditional.enum_for(:each).each_with_index.inject('') do |output, (child, index)|
          local_variables_stack.push({ 'index' => index })
          output << visit(node.template, child)
          local_variables_stack.pop
          output
        end
      elsif conditional && !(conditional.respond_to?(:empty?) && conditional.empty?)
        visit(node.template, context)
      else
        visit(node.inverse, context)
      end
    end

    def visit_NilClass(node, context)
      ''
    end

    def visit_BooleanNode(node, context)
      node.value === 'true'
    end

    def visit_NumberNode(node, context)
      node.value.to_i
    end

    def visit_StringNode(node, context)
      node.value
    end

    def visit_PartialNode(node, context)
      partial = partials.lookup(node.name)
      context = node.context_id ? visit(node.context_id, context) : context

      if partial
        visit(partial, context)
      else
        "Missing partial '#{node.name}'"
      end
    end

    def visit_HashNode(node, context)
      node.pairs.each_with_object({}) do |(key, value), output|
        output[key] = visit(value, context)
      end
    end

    def visit_DataNode(node, context)
      return '' unless local_variables = local_variables_stack.last
      local_variables[node.id.to_s].to_s
    end

    def escape(output)
      return output if output.kind_of?(Tempo::SafeString)

      CGI.escapeHTML(output).gsub(/(['`])/, {
        "'" => '&#39;',
        '`' => '&#x60;'
      })
    end

    def local_variables_stack
      @local_variables ||= []
    end

  end
end