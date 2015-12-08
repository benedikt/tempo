require 'rltk'
require 'tempo/nodes'

module Tempo
  class Parser < RLTK::Parser

    start :root

    left :SEP
    right :EQUALS, :ID

    production(:root) do
      clause('statements') { |statements| Nodes::TemplateNode.new(statements) }
    end

    production(:template) do
      clause('statements') { |statements| Nodes::TemplateNode.new(statements) }
      clause('') { Nodes::TemplateNode.new([]) }
    end

    production(:statements) do
      clause('statement') { |statement| [statement] }
      clause('statements statement') { |statements, statement| statements << statement }
    end

    production(:statement) do
      clause('open_inverse block_contents close_block') do |expression, contents, close|
        raise unless expression[0] == close
        Nodes::BlockExpressionNode.new(expression[0], expression[1], expression[2], contents[1], contents[0])
      end

      clause('open_block block_contents close_block') do |expression, contents, close|
        raise unless expression[0] == close
        Nodes::BlockExpressionNode.new(expression[0], expression[1], expression[2], contents[0], contents[1])
      end

      clause('expression') { |expression| expression }
      clause('partial') { |partial| partial }
      clause('CONTENT') { |content| Nodes::ContentNode.new(content) }
      clause('COMMENT') { |content| Nodes::CommentNode.new(content) }
    end

    production(:block_contents) do
      clause('simple_inverse template') { |_, inverse| [nil, inverse] }
      clause('template simple_inverse') { |template, _| [template, nil] }
      clause('template simple_inverse template') { |template, _, inverse| [template, inverse] }
      clause('simple_inverse') { |_| [nil, nil] }
      clause('template') { |template| [template, nil] }
    end

    production(:open_block) do
      clause('OPEN_BLOCK expression_contents CLOSE') { |_, contents, _| contents }
    end

    production(:open_inverse) do
      clause('OPEN_INVERSE expression_contents CLOSE') { |_, contents, _| contents }
    end

    production(:close_block) do
      clause('OPEN_ENDBLOCK path CLOSE') { |_, path, _| path }
    end

    production(:expression) do
      clause('OPEN expression_contents CLOSE') do |_, contents, _|
        Nodes::ExpressionNode.new(contents[0], contents[1], contents[2])
      end

      clause('OPEN_UNESCAPED_AMP expression_contents CLOSE') do |_, contents, _|
        Nodes::UnescapedExpressionNode.new(contents[0], contents[1], contents[2])
      end

      clause('OPEN_UNESCAPED expression_contents CLOSE_UNESCAPED') do |_, contents, _|
        Nodes::UnescapedExpressionNode.new(contents[0], contents[1], contents[2])
      end
    end

    production(:partial) do
      clause('OPEN_PARTIAL partial_name path? CLOSE') { |_, name, path, _| Nodes::PartialNode.new(name, path) }
    end

    production(:simple_inverse) do
      clause('OPEN_INVERSE CLOSE') { |_, _| }
    end

    production (:expression_contents) do
      clause('path param+ hash?') { |path, params, hash| [path, params, hash] }
      clause('path hash?') { |path, hash| [path, [], hash] }
      clause('data_name') { |data| [data, [], nil] }
    end

    production(:param) do
      clause('path') { |path| path }
      clause('STRING') { |string| Nodes::StringNode.new(string) }
      clause('NUMBER') { |string| Nodes::NumberNode.new(string) }
      clause('BOOLEAN') { |string| Nodes::BooleanNode.new(string) }
      clause('data_name') { |data| data }
    end

    production(:hash) do
      clause('hash_segment+') { |hash_segments| Nodes::HashNode.new(hash_segments) }
    end

    production(:hash_segment) do
      clause('ID EQUALS param') { |id, _, value| [id, value] }
    end

    production(:partial_name) do
      clause('partial_path') { |path| path.join }
      clause('STRING') { |path| path }
      clause('NUMBER') { |path| path }
    end

    production(:partial_path) do
      clause('partial_path SEP ID') { |path, separator, id| path << separator << id }
      clause('ID') { |id| [id] }
    end

    production(:data_name) do
      clause('DATA ID') { |_, id| Nodes::DataNode.new(id) }
    end

    production(:path) do
      clause('path_segments') { |path_segments| Nodes::CallNode.new(path_segments) }
    end

    production(:path_segments) do
      clause('path_segments SEP ID') { |path_segments, separator, id| path_segments << id }
      clause('ID') { |id| [id] }
    end

    finalize(:lookahead => false, :use => File.expand_path('../parser.rltk', __FILE__))
  end
end
