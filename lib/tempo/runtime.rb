require 'cgi'

module Tempo
  class Runtime

    def initialize
      yield self if block_given?
    end

    attr_writer :partials, :helpers

    def partials
      @partials ||= Tempo::PartialContext.new
    end

    def helpers
      @helpers ||= Tempo::HelperContext.new
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
        helper.call(*arguments, options).to_s
      else
        visit(node.path, context)
      end
    end

    def visit_ExpressionNode(node, context)
      escape(visit_UnescapedExpressionNode(node, context))
    end

    def visit_CallNode(node, context)
      context.fetch(node.id, '')
    end

    def visit_PathNode(node, context)
      node.ids.inject(context) do |ctx, segment|
        visit(segment, ctx)
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
        conditional.call(*arguments, options).to_s
      elsif conditional.respond_to?(:each)
        conditional.enum_for(:each).inject('') do |output, child|
          output << visit(node.template, child)
        end
      elsif conditional
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

    def escape(output)
      CGI.escapeHTML(output).gsub(/(['`])/, {
        "'" => '&#39;',
        '`' => '&#x60;'
      })
    end

  end
end