require 'rltk/ast'

module Tempo
  module Nodes
    class Node < RLTK::ASTNode
    end

    class TemplateNode < Node
      child :statements, [Node]

      def to_s
        statements.map(&:to_s).join(' ')
      end
    end

    class IdNode < Node
    end

    class CallNode < IdNode
      value :ids, [String]

      def to_s
        if ids.size == 1
          "ID(#{ids.first})"
        else
          "PATH(#{ids.join(' ')})"
        end
      end
    end

    class DataNode < IdNode
      value :id, String

      def to_s
        "DATA(#{id})"
      end
    end

    class ContentNode < Node
      value :value, String

      def to_s
        "CONTENT(#{value.inspect})"
      end
    end

    class HashNode < Node
      value :pairs, Array

      def to_s
        contents = pairs.map do |(key, value)|
          "#{key}=#{value}"
        end.join(' ')

        "{#{contents}}"
      end
    end

    class PartialNode < Node
      value :name, String
      child :context_id, IdNode

      def to_s
        "PARTIAL(#{name} #{context_id})"
      end
    end

    class StringNode < Node
      value :value, String

      def to_s
        "STRING(#{value.inspect})"
      end
    end

    class NumberNode < Node
      value :value, String

      def to_s
        "NUMBER(#{value})"
      end
    end

    class BooleanNode < Node
      value :value, String

      def to_s
        "BOOLEAN(#{value})"
      end
    end

    class CommentNode < Node
      value :comment, String

      def to_s
        "COMMENT(#{comment.inspect})"
      end
    end

    class ExpressionNode < Node
      child :path, IdNode
      child :params, [Node]
      child :hash, HashNode

      def to_s
        "EXPRESSION(#{path} [#{params.map(&:to_s).join(' ')}] #{hash})"
      end
    end

    class BlockExpressionNode < ExpressionNode
      child :template, TemplateNode
      child :inverse, TemplateNode

      def to_s
        "BLOCK(#{path} [#{params.map(&:to_s).join(' ')}] #{hash} TEMPLATE(#{template}) INVERSE(#{inverse}))"
      end
    end

    class UnescapedExpressionNode < ExpressionNode
      def to_s
        'UNESCAPED_' + super
      end
    end
  end
end