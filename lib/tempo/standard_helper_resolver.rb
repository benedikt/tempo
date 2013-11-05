require 'tempo/helper_utilities'
require 'tempo/helper_resolver'

module Tempo
  class StandardHelperResolver < HelperResolver
    class Each
      extend Tempo::HelperUtilities

      def self.call(collection, options)
        if present?(collection) && map?(collection)
          collection.enum_for(:each).each_with_index.map do |(key, value), index|
            yield value, { 'index' => index, 'key' => key }
          end.join
        elsif present?(collection) && collection?(collection)
          collection.enum_for(:each).each_with_index.map do |element, index|
            yield element, { 'index' => index }
          end.join
        else
          yield :inverse
        end
      end
    end

    class If
      extend Tempo::HelperUtilities

      def self.call(condition, options)
        present?(condition) ? yield : yield(:inverse)
      end
    end

    class Unless
      extend Tempo::HelperUtilities

      def self.call(condition, options)
        blank?(condition) ? yield : yield(:inverse)
      end
    end

    class With
      def self.call(object, options)
        yield object
      end
    end

    class Log
      def initialize(output = STDOUT)
        @output = output
      end

      def call(message, options)
        @output.puts(message)
      end
    end

    def initialize
      register(:each, Each)
      register(:if, If)
      register(:unless, Unless)
      register(:with, With)
      register(:log, Log.new)
    end
  end
end