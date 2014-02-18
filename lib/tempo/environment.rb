module Tempo
  class Environment

    attr_reader :options

    def initialize(attributes = {})
      @options = attributes[:options] || {}
      push_context(attributes[:context]) if attributes[:context]
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

    def with(arguments)
      variables, context = arguments[:variables], arguments[:context]
      push_variables(variables) if variables
      push_context(context) if context
      yield
    ensure
      pop_variables if variables
      pop_context if context
    end

    def isolated
      @options, original_options = options.clone, options
      @context_stack, original_context_stack = context_stack.clone, context_stack
      @variables_stack, original_variables_stack = variables_stack.clone, variables_stack
      yield
    ensure
      @options = original_options
      @context_stack = original_context_stack
      @variables_stack = original_variables_stack
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