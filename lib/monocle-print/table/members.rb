#!/usr/bin/ruby
# encoding: utf-8

module MonoclePrint
class Table
class Member
  include MonoclePrint
  include Enumerable

  class << self
    attr_reader :member_name
    def define( member_name, sup = self, &body )
      klass =
        Class.new( sup ) do
          @member_name = member_name
          class_eval( &body )
        end

      define_method( "#{ member_name }!" ) do |*args|
        klass.new( @table, *args ) { |m| link( m ) }.tail
      end
      return( klass )
    end
  end

  attr_reader :table
  attr_accessor :before, :after
  protected :before=, :after=

  def initialize( table, *args )
    @table    = table
    @before   = nil
    @after    = nil
    @disabled = false
    block_given? and yield( self )
    initialize!( *args )
  end

  def initialize!( * )
    # do nothing
  end

  def inspect( *args )
    content = args.map! { |a| a.inspect }.join(', ')
    "#{self.class.member_name}(#{content})"
  end

  def each
    block_given? or return( enum_for( __method__ ) )
    node = self
    begin
      yield( node )
      node = node.after
    end while( node )
  end

  def disable
    @disabled = true
  end

  def enable
    @disabled = false
  end

  def enabled?
    not disabled?
  end

  def disabled?
    @disabled
  end

  def first?
    @before.nil?
  end

  def last?
    @after.nil?
  end

  def link( item )
    after, @after, item.before = @after, item, self
    after ? item.link( after ) : item
  end

  def unlink
    @before and @before.after = nil
    @before = nil
    return( self )
  end

  def render( out, style )
    render!( out, style ) unless disabled?
  end

  def columns
    table.columns
  end

  def tail
    @after ? @after.tail : self
  end
end

Blank =
  Member.define( 'blank' ) do
    def render!( * )
    end
  end

Row =
  Member.define( 'row' ) do
    def initialize!( *content )
      @cells = [ content ].flatten!.map! { | c | Text( c ) }
      @table.expand_columns( @cells.length )
    end

    def []( index )
      @cells[ index ]
    end

    def []=(index, value)
      @cells[ index ] = value
    end

    def cells
      @table.columns.zip( @cells ).
        map! { | col, cell | col.prepare( cell ) }
    end

    def height
      cells.map! { | c | c.height }.max
    end

    def render!( out, style )
      cells =
        @table.columns.zip( @cells ).map! do | col, cell |
          col.prepare( cell )
        end

      height = cells.map { | col, cell | cell ? cell.height : 1 }.max

      joint = style.format( ' <v> ' )
      left  = style.format( '<v> ' )
      right = style.format( ' <v>' )

      result = cells.inject { | result, cell | result.juxtapose( cell, joint ) }
      result.each do | line |
        out.put!( left + line + right )
      end
      return( out )
    end

    def inspect
      super( *cells )
    end

  private

    def prepare
      height = cells.map { | c | c.height }.max
      if height > 1
        cell_lines.zip( @table.columns ) do | lines, col |
          if lines.length < height
            blank = col.fill_text( ' ' )
            lines.fill( blank, lines.length, height - lines.length )
          end
        end
      end
      return( cell_lines )
    end

    def pad
      n = @table.columns.length
      m = @cells.length
      @cells.fill( Text(' '), m, n - m ) if n > m
    end
  end

TitleRow =
  Member.define( 'title_row', Row ) do
    def initialize!( *content )
      super
      divider!( :title )
    end
  end

Divider =
  Member.define( 'divider' ) do
    attr_accessor :type

    def initialize!( type )
      @type = type.to_sym
    end

    def render( out, style )
      super( out, style ) unless @after.is_a?( Divider )
    end

    def inspect( *args )
      super( @type, *args )
    end

    def render!( out, style )
      fills = @table.columns.map { | c | "<h:#{ c.width + 2 }>" }
      template =
        case @type
        when :row, :title
          '<nse>' << fills.join( '<hv>' ) << '<nsw>'
        when :section_open
          '<nse>' << fills.join( '<hs>' ) << '<nsw>'
        when :section_close
          '<nse>' << fills.join( '<hn>' ) << '<nsw>'
        when :head
          '<se>' << fills.join( '<hs>' ) << '<sw>'
        when :foot
          '<ne>' << fills.join( '<hn>' ) << '<nw>'
        end
      out.puts( style.format( template ) )
    end
  end

SectionTitle =
  Member.define( 'section' ) do
    attr_accessor :title, :alignment

    def initialize!( title, options = {} )
      @title = Text( title )
      @alignment = options.fetch( :align, :left )
      @before.divider!( :section_close )
      divider!( :section_open )
    end

    def inspect
      super( @title, @alignment )
    end

    def render!( out, style )
      w     = @table.inner_width
      title = @title.width > w ? @title.wrap( w ) : @title
      left  = style.format( '<v> ' )
      right = style.format( ' <v>' )

      for line in title.align( @alignment, w )
        out.puts(  left + line + right )
      end
    end

  end

end
end
