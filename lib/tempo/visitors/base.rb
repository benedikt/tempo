module Tempo
  module Visitors
    class Base

      NODE_LOOKUP_CACHE = Hash.new { |cache, node| cache[node] = "visit_#{node.name.split('::').last}" }

      def visit(node)
        send(NODE_LOOKUP_CACHE[node.class], node)
      end

    end
  end
end
