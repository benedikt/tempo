class Object
  def to_tempo_context
    Tempo::Context.new(self)
  end
end

class String
  def to_tempo_context
    Tempo::StringContext.new(self)
  end
end

module Enumerable
  def to_tempo_context
    Tempo::EnumerableContext.new(self)
  end
end

class Hash
  def to_tempo_context
    Tempo::HashContext.new(self)
  end
end

class Numeric
  def to_tempo_context
    Tempo::StringContext.new(to_s)
  end
end

class TrueClass
  def to_tempo_context
    Tempo::StringContext.new(to_s)
  end
end

class FalseClass
  def to_tempo_context
    self
  end
end
