require 'delegate'

module Tempo
  class Context < SimpleDelegator
    class << self
      def allows(*attributes)
        invokable_methods.concat(attributes.map(&:to_s))
      end

      def invokable_methods
        @invokable_methods ||= if self != Tempo::Context
          superclass.invokable_methods.dup
        else
          []
        end
      end
    end

    def invoke(method)
      if has_invokable_method?(method)
        public_send(method).to_tempo_context
      else
        nil
      end
    end

    alias :[] :invoke

    def has_invokable_method?(method)
      self.class.invokable_methods.include?(method.to_s)
    end

    def to_tempo_context
      self
    end

    def to_s
      ''
    end

    def inspect
      "#<#{self.class} for #{__getobj__.inspect}>"
    end
  end

  class HashContext < Context
    def invoke(key)
      result = __getobj__.fetch(key, '')
      result = result.call if result.respond_to?(:call)
      result.to_tempo_context
    end

    def has_invokable_method?(method)
      __getobj__.has_key?(method)
    end
  end

  class EnumerableContext < Context
    allows :first, :last, :count, :size, :length, :reverse
  end

  class StringContext < Context
    def to_s
      __getobj__
    end

    alias :to_str :to_s
  end
end