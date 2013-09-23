#!/usr/bin/ruby
# encoding: utf-8

module MonoclePrint
class Table
class Column
  include MonoclePrint

  def initialize( table, index )
    @table        = table
    @index        = index
    @wrap         = false
    @flow         = false
    @alignment    = :left
    @fixed_width  = nil
    @cached_width = nil
  end

  attr_reader   :table, :index
  attr_accessor :alignment

  for m in %w( wrap flow )
    attr_accessor( m )
    alias_method( "#{m}?", m )
    undef_method( m )
  end

  def malleable?
    @wrap and @flow
  end

  def malleable=( bool )
    @wrap = @flow = bool
  end

  def fixed?
    not malleable?
  end

  def fixed=( bool )
    self.malleable = !bool
  end

  def title
    @table.titles[ @index ]
  end

  def cells
    @table.grep( Row ) { | row | row[ @index ] || Line( '' ) }
  end

  def previous_column
    @index.zero? ? nil : @table.columns[ @index - 1 ]
  end

  def next_column
    @table.columns[ @index + 1 ]
  end

  def first?
    @index.zero?
  end

  def last?
    @index == (table.columns.length - 1)
  end

  def prepare( cell_text )
    cell_text = cell_text ? cell_text.dup : Text( ' ' )
    @flow and cell_text.reflow!( false )
    @wrap and cell_text = cell_text.wrap( width - 1 )
    cell_text.align!( @alignment, width )
  end

  def width=( w )
    @fixed_width = Utils.at_least( w.to_i, 1 )
  end

  def width
    @fixed_width or @cached_width or calculate_width
  end

  def calculate_metrics
    @cached_width = @fixed_width || calculate_width
  end

  def clear_metrics
    @cached_width = nil
  end

protected

  def calculate_width
    @table.grep( Row ) { |r| c = r[ @index ] and c.width or 0 }.max || 0
  end
end
end
end
