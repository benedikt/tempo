require 'cgi'
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

        if helper = lookup_helper(node.path)
          call_helper(helper, arguments, options)
        else
          visit(node.path)
        end.to_s
      end

      def visit_ExpressionNode(node)
        escape(visit_UnescapedExpressionNode(node))
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
          elsif index == 0 && helper = lookup_helper(segment)
            parent_allowed = false
            call_helper(helper)
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

        conditional = if helper = lookup_helper(node.path)
          helper
        else
          visit(node.path)
        end

        if conditional.respond_to?(:call)
          call_helper(conditional, arguments, options) do |variant, local_context, local_variables|
            variant, local_context, local_variables, = :template, variant, local_context unless variant.kind_of?(Symbol)

            environment.with(:context => local_context, :variables => local_variables) do
              visit(node.send(variant))
            end
          end.to_s
        elsif !conditional.kind_of?(HashContext) && conditional.respond_to?(:each) && conditional.enum_for(:each).count > 0
          conditional.enum_for(:each).each_with_index.inject('') do |output, (child, index)|
            environment.with(:context => child, :variables => { 'index' => index }) do
              output << visit(node.template)
            end
          end
        elsif conditional && !(conditional.respond_to?(:empty?) && conditional.empty?)
          environment.with(:context => conditional) do
            visit(node.template)
          end
        else
          visit(node.inverse)
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
        if partial = runtime.partials.lookup(node.name)
          context = node.context_id && visit(node.context_id)

          environment.with(:context => context) do
            visit(partial)
          end
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

    private

      def escape(output)
        return output if output.kind_of?(Tempo::SafeString)

        CGI.escapeHTML(output).gsub(/(['`])/, {
          "'" => '&#39;',
          '`' => '&#x60;'
        })
      end

      def lookup_helper(node)
        if node.kind_of?(Nodes::CallNode) && node.ids.size == 1
          runtime.helpers.lookup(node.ids.first)
        else
          runtime.helpers.lookup(node)
        end
      end

      def call_helper(helper, arguments = [], options = {}, &block)
        options = options.merge({
          :_runtime => runtime,
          :_environment => environment
        })

        helper.call(*arguments, options, &block)
      end
    end
  end
end