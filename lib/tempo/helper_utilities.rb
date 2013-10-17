module Tempo
  module HelperUtilities
    def blank?(object)
      object.respond_to?(:empty?) ? object.empty? : !object
    end

    def present?(object)
      !blank?(object)
    end

    def collection?(object)
      object.respond_to?(:each)
    end

    def map?(object)
      collection?(object) && object.respond_to?(:keys)
    end
  end
end