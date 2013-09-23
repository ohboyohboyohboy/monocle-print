#!/usr/bin/ruby
# encoding: utf-8

module MonoclePrint
  module Utils
    module_function

    def at_least( comparable, min )
      ( comparable >= min ) ? comparable : min
    end

    def at_most( comparable, max )
      ( comparable <= max ) ? comparable : max
    end

    def bound( comparable, lower, upper = nil )
      return lower if comparable < lower
      return comparable unless upper
      return upper if comparable > upper
      return comparable
    end
  end
end
