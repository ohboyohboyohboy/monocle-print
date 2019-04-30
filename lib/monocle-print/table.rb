#!/usr/bin/ruby

require 'monocle-print/table/segments'
require 'monocle-print/table/members'
require 'monocle-print/table/column'

module MonoclePrint
class Table
  include MonoclePrint
  include Presentation
  include Enumerable
  
  def self.build( *args )
    table = new( *args ) do | table |
      block_given? and yield( table )
    end
    return( table.render )
  end
  
  
  def initialize( columns, options = {} )
    initialize_view( options )
    
    @titles = nil
    @item = @head = Divider.new( self, :head )
    @foot = Divider.new( self, :foot )
    @columns = []
    @body = []
    
    case columns
    when Integer
      expand_columns( columns )
    when Array
      title_row( *columns )
    end
    
    block_given? and yield( self )
  end
  
  def render_content( out )
    style = @style || out.style
    lock do
      width > out.width and resize( out.width )
      each { | member | member.render( out, style ) }
    end
  end
  
  def each
    block_given? or return( enum_for( :each ) )
    for item in @head
      yield( item )
    end
  end
  
  attr_reader :columns, :titles
  
  def row( *members )
    @item = @item.row!( *members )
  end
  
  def title_row( *members )
    @titles = @item = @item.title_row!( *members )
    while @titles
      if TitleRow === @titles
        @titles = @titles.cells.map { | c | c.to_s }
        break
      end
      @titles = @titles.before
    end
    self
  end
  
  def rows( *list_of_rows )
    for row in list_of_rows do row( *row ) end
    self
  end
  
  def section( title, options = {} )
    @item = @item.section!( title, options )
  end
  
  def divider( type = :row_divider )
    @item = @item.divider!( type )
  end
  
  def fixed_columns( *column_indicies )
    for column_index in column_indicies
      if c = column( column_indicies )
        if Array === c then c.each { | i | i.fixed = true }
        else c.fixed = true
        end
      end
    end
  end
  
  def malleable_columns( *column_indicies )
    for column_index in column_indicies
      if c = column( column_index )
        if Array === c then c.each { | i | i.malleable = true }
        else c.malleable = true
        end
      end
    end
  end
  
  def column( name_or_index )
    case name_or_index
    when Integer, Range then @columns[ name_or_index ]
    else
      @columns.find do | col |
        name_or_index === col.title
      end
    end
  end
  
  def resize( new_size )
    resizable = @columns.select { | c | c.malleable? }
    if resizable.empty?
      warn( "cannot resize #{ self.inspect } as all columns are fixed" )
      return( self )
    end
    
    lock do
      difference = new_size - @width
      resize_columns( difference, resizable )
    end
    
    return( self )
  end
  

  
  def inner_width
    @inner_width or calculate_inner_width
  end
  
  def width
    @width or calculate_width
  end
  
  def expand_columns(new_size)
    new_size.zero? and return
    
    until @columns.length >= new_size
      @columns << Column.new( self, @columns.length )
    end
  end

private
  
  def resize_columns( amount, columns )
    leftover = amount
    resizable_area = columns.inject( 0 ) do | sz, c |
      sz + c.width
    end
    
    for column in columns
      proportion = ( column.width.to_f / resizable_area )
      delta = ( proportion * amount ).round
      column.width += delta
      leftover -= delta
    end
    
    columns.last.width += leftover
  end
  
  def expand( amount, columns )
    leftover = amount
    resizable_area = columns.inject( 0 ) do | sz, c |
      sz + c.width
    end
    
    for column in columns
      proportion = ( column.width.to_f / resizable_area )
      delta = ( proportion * amount ).round
      column.width += delta
      leftover -= delta
    end
    
    columns.last.width += leftover
  end
  
  
  
  def lock
    calculate_metrics
    @item.link( @foot )
    yield
  ensure
    @foot.unlink
    clear_metrics
  end
  
  def calculate_metrics
    @columns.each { | c | c.calculate_metrics }
    @inner_width = calculate_inner_width
    @width = calculate_width
  end
  
  def clear_metrics
    @columns.each { | c | c.clear_metrics }
    @inner_width = nil
    @width = nil
  end
  
  def calculate_inner_width
    w = @columns.inject( 0 ) { | w, c | w + c.width }
    w + ( @columns.length - 1 ) * 3
  end
  
  def calculate_width
    calculate_inner_width + 4
  end
  
end

class ColumnLayout < Table
  def initialize( columns, options = {} )
    super( columns, options ) do
      @item  = @head = Blank.new( self )
      @foot  = Blank.new( self )
      @style = Style( :blank )
      block_given? and yield( self )
    end
  end
end

end

