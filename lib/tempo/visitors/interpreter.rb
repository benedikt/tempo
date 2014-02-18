require 'tempo/visitors/base'

module Tempo
  module Visitors
    class Interpreter < Base

      attr_reader :runtime, :environment

      def initialize(runtime, environment)
        @runtime = runtime
        @environment = environment
      end

      def visit_String(node)
        template = Parser.parse(Lexer.lex(node))
        visit(template)
      end

      def visit_TemplateNode(node)
        node.statements.each_with_object('') do |statement, output|
          output << visit(statement)
        end
      end

      def visit_ContentNode(node)
        node.value
      end

      def visit_UnescapedExpressionNode(node)
        arguments = node.params.map { |p| visit(p) }
        options = node.hash && visit(node.hash) || {}

        if helper = runtime.lookup_helper(node.path)
          helper.call(*arguments, options)
        else
          visit(node.path)
        end.to_s
      end

      def visit_ExpressionNode(node)
        runtime.escape(visit_UnescapedExpressionNode(node))
      end

      def visit_CallNode(node)
        @environment, old_environment = environment.clone, environment

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
            environment.pop_context
            environment.local_context.to_tempo_context
          elsif index == 0 && helper = runtime.lookup_helper(segment)
            parent_allowed = false
            helper.call
          else
            parent_allowed = false
            ctx = ctx.to_tempo_context
            ctx && ctx.invoke(segment)
          end
        end
      ensure
        @environment = old_environment
      end

      def visit_CommentNode(node)
        ''
      end

      def visit_BlockExpressionNode(node)
        arguments = node.params.map { |p| visit(p) }
        options = node.hash && visit(node.hash) || {}

        conditional = if helper = runtime.lookup_helper(node.path)
          helper
        else
          visit(node.path)
        end

        if conditional.respond_to?(:call)
          conditional.call(*arguments, options) do |variant, local_context, local_variables|
            variant, local_context, local_variables, = :template, variant, local_context unless variant.kind_of?(Symbol)

            environment.push_variables(local_variables)
            environment.push_context(local_context) if local_context
            result = visit(node.send(variant))
            environment.pop_context if local_context
            environment.pop_variables
            result
          end.to_s
        elsif !conditional.kind_of?(HashContext) && conditional.respond_to?(:each) && conditional.enum_for(:each).count > 0
          conditional.enum_for(:each).each_with_index.inject('') do |output, (child, index)|
            environment.push_variables({ 'index' => index })
            environment.push_context(child)
            output << visit(node.template)
            environment.pop_context
            environment.pop_variables
            output
          end
        elsif conditional && !(conditional.respond_to?(:empty?) && conditional.empty?)
          environment.push_context(conditional)
          result = visit(node.template)
          environment.pop_context
          result
        else
          result = visit(node.inverse)
          result
        end
      end

      def visit_NilClass(node)
        ''
      end

      def visit_BooleanNode(node)
        node.value === 'true'
      end

      def visit_NumberNode(node)
        node.value.to_i
      end

      def visit_StringNode(node)
        node.value
      end

      def visit_PartialNode(node)
        partial = runtime.partials.lookup(node.name)

        if partial
          environment.push_context(visit(node.context_id)) if node.context_id
          result = visit(partial)
          environment.pop_context if node.context_id
          result
        else
          "Missing partial '#{node.name}'"
        end
      end

      def visit_HashNode(node)
        node.pairs.each_with_object({}) do |(key, value), output|
          output[key] = visit(value)
        end
      end

      def visit_DataNode(node)
        return '' unless local_variables = environment.local_variables
        local_variables[node.id.to_s]
      end

    end
  end
end