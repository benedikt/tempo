module Tempo
  class PartialResolver

    def register(name, partial)
      partials[name.to_s] = partial
    end

    def lookup(name)
      partials[name.to_s]
    end

  private

    def partials
      @partials ||= {}
    end

  end
end