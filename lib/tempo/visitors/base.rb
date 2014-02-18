module Tempo
  module Visitors
    class Base

      def visit(node)
        send("visit_#{node.class.name.split('::').last}", node)
      end

    end
  end
end