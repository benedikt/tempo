module Tempo
  class HelperResolver

    def register(name, helper = nil, &block)
      helpers[name.to_s] = helper || block
    end

    def lookup(name)
      helpers[name.to_s]
    end

  private

    def helpers
      @helpers ||= {}
    end

  end
end