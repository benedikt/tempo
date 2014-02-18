module Tempo
  class Environment

    attr_reader :options

    def initialize(attributes = {})
      @options = attributes[:options] || {}
      push_context(attributes[:context]) if attributes[:context]
    end

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