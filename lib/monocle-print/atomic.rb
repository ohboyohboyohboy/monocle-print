#!/usr/bin/ruby
# encoding: ascii
#
# author: Kyle Yetter
#

require 'monocle-print'

module MonoclePrint
  if RUBY_VERSION =~ /^1\.8/
    MULTIBYTE_CHARACTER = %r<
      [\xC2-\xDF][\x80-\xBF]
    | [\xE0-\xEF][\x80-\xBF]{2}
    | [\xF0-\xF4][\x80-\xBF]{3}
    >x

    ONE_BYTE    = 0x20 .. 0x7E
    TWO_BYTES   = 0xC2 .. 0xDF
    THREE_BYTES = 0xE0 .. 0xEF
    FOUR_BYTES  = 0xF0 .. 0xF4
  end

  COLOR_ESCAPE = /\e\[[\d:;]*?m/

  class SingleLine < ::String
    include MonoclePrint

    def self.clear_cache
      @@width.clear
      @@invisible_size.clear
      return( self )
    end

    @@width = {}
    @@invisible_size = {}

    if RUBY_VERSION =~ /^1\.8/

      def char_byte( n )
        n.zero? and return( 0 )
        seen = byte = 0
        while c = self[ byte ] and seen < n
          step =
            case c
            when ONE_BYTE then seen += 1; 1
            when ?\e
              self[ byte, size ] =~ /^#{COLOR_ESCAPE}/ ? $~.end(0) : 1
            when TWO_BYTES then seen += 1; 2
            when THREE_BYTES then seen += 1; 3
            when FOUR_BYTES then seen += 1; 4
            else 1
            end
          byte += step
        end
        return( byte )
      end

      def width
        @@width[ hash ] ||= begin
          (temp = bleach).gsub!( MULTIBYTE_CHARACTER, ' ' )
          temp.size
        end
      end

    else

      def char_byte( n )
        seen = byte = 0
        if esc = self =~ COLOR_ESCAPE and esc < n
          return( $~.end(0) + $'.char_byte( n - esc ) )
        else n
        end
      end

      def width
        @@width[ hash ] ||= bleach.length
      end

    end

    def align( alignment, width, fill = ' ' )
      dup.align!( alignment, width, fill )
    end

    def align!( alignment, width, fill = ' ' )
      case alignment.to_sym
      when :left then left!( width, fill )
      when :center then center!( width, fill )
      when :right then right!( width, fill )
      end
    end

    def blank?
      empty? or self =~ /^(\s|#{COLOR_ESCAPE})*$/
    end

    def bleach
      gsub( COLOR_ESCAPE, '' )
    end

    def bleach!
      gsub!( COLOR_ESCAPE, '' )
    end

    def center!( w, fill = ' ' )
      w > width or return( self )
      if fill.length == 1
        replace( center( w + invisible_size, fill ) )
      else fill = self.class.new( fill )
        even, odd = ( width - w ).divmod( 2 )
        insert( 0, fill.tile( even ) )
        self << fill.tile( even + odd )
      end
      self
    end

    def divide_at( len )
      pos = char_byte( len )
      return( [ self[ 0, pos ], self[ pos, size ] ] )
    end

    def each_escape
      block_given? or return( enum_for( :each_escape ) )
      scan( COLOR_ESCAPE ) do |esc|
        yield( esc )
      end
    end

    def escapes
      each_escape.inject( self.class.new ) do | escs, esc |
        escs << esc
      end
    end

    def indent( n )
      dup.indent!( n )
    end

    def indent!( num_spaces )
      if num_spaces < 0
        remaining_indent = Utils.at_least( level_of_indent + num_spaces, 0 )
        lstrip!
        indent!( remaining_indent )
      else
        insert( 0, ' ' * num_spaces )
      end
      return( self )
    end

    def invisible_size
      @@invisible_size[ hash ] ||= size - width
    end

    def left!( w, fill = ' ' )
      w > width or return( self )
      if fill.length == 1
        replace( ljust( w + invisible_size, fill ) )
      else fill = self.class.new( fill )
        insert( 0, fill.tile( width - w ) )
      end
      self
    end

    def level_of_indent
      self =~ /^(\s+)/ ? $1.length : 0
    end

    def pad!( left, right = left )
      right!( width + left )
      left!( width + right )
    end

    def partial(len)
      self[ 0, char_byte( len ) ]
    end

    def right!( w, fill = ' ' )
      w > width or return( self )
      if fill.length == 1
        replace( rjust( w + invisible_size, fill ) )
      else fill = self.class.new( fill )
        self.insert( 0, fill.tile( w - width ) )
      end
      self
    end

    def tile( size )
      width == 0 and return( )
      full, partial = size.divmod( width )
      self * full << partial( partial )
    end

    def truncate( w, tail = nil )
      dup.truncate!( w, tail )
    end

    def truncate!( w, tail = nil )
      width > w or return( self )
      if tail then tail = Line( tail )
        return( partial( w - tail.width ) << tail )
      else
        return( partial( w ) )
      end
      return( self )
    end

    def words
      strip.split(/\s+/)
    end

    def height
      1
    end

    def wrap( w )
      if width > w
        words = split( /\s+/ ).inject( [] ) do | words, word |
          while word.width > w
            frag, word = word.divide_at( w )
            words << frag
          end
          words << word
        end

        line = words.shift || self.class.new
        text = Text.new
        w -= 1
        while word = words.shift
          if line.width + word.width > w
            text << line
            line = word
          else
            line << ' ' << word
          end
        end
        text << line
        return( text )
      else
        return( Text( self.dup ) )
      end
    end
  end

  class Text < Array
    def self.clear_cache
      @@width.clear
      @@uniform.clear
      return( self )
    end

    include MonoclePrint
    @@width = {}
    @@uniform = {}

    def initialize( lines = nil, default = nil )
      case lines
      when Fixnum
        if block_given?
          super( lines ) { | i | Line( yield( i ) ) }
        else
          default = Line( default )
          super( lines, default )
        end
      when Text then super( lines )
      when Array
        super( lines.join( $/ ).map { | l | Line( l.chomp! || l ) } )
      when SingleLine then super(1, lines)
      when nil then super()
      else
        super( lines.to_s.lines.map { |l| Line( l.chomp! || l ) } )
      end
    end

    def initialize_copy( orig )
      for line in orig
        self << line.dup
      end
    end

    def align( alignment, width, fill = ' ' )
      dup.align!( alignment, width, fill )
    end

    def align!( alignment, width, fill = ' ' )
      # if the width argument is less than the full block width of the text,
      # make it the full block width to ensure uniform width
      width = Utils.at_least( width, self.width )

      if empty?
        self << SingleLine.new( ' ' * width )
      else
        map! do | line |
          line.align( alignment, width, fill )
        end
      end

      return( self )
    end

    def bleach
      dup.bleach!
    end

    def bleach!
      each { | l | l.bleach! }
    end

    def fix
      dup.fix!
    end

    def fix!
      align!( :left, width )
    end

    def fixed_indent!( level = 0 )
      level = Utils.at_least( level, 0 )
      offset = level - level_of_indent
      indent!( offset )
    end

    def fixed_indent( level = 0 )
      dup.fixed_indent!( level )
    end

    def level_of_indent
      level = nil
      levels = map { | line | line.blank? ? nil : line.level_of_indent }
      levels.compact!
      levels.min || 0
    end

    def indent!( spaces )
      for line in self do line.indent!( spaces ) end
      self
    end

    def indent( spaces )
      dup.indent!( spaces )
    end

    def frame( graphic_style )
      dup.frame!( graphic_style )
    end

    def frame!( graphic_style )
      top = graphic_style.box_top( width )
      bottom = graphic_style.box_bottom( width )
      for line in self
        line.insert( 0, graphic_style.v )
        line.insert( -1, graphic_style.v )
      end
      unshift( top )
      push( bottom )
      return( self )
    end

    def inspect
      digits = Math.log10( Utils.at_least( length, 1 ) ).floor + 1
      $/ + each_with_index.map do | line, i |
        line_no = i.to_s.rjust( digits )
        "#{ line_no } | #{ line }"
      end.join( $/ ) + $/
    end

    def juxtapose( text, joint = ' ' )
      dup.juxtapose!( text, joint )
    end

    def juxtapose!( text, joint = ' ' )
      text = self.class.new( text ).fix!.valign!( :top, height )
      valign!( :top, text.height ); fix!

      zip( text ) do | left, right |
        left << joint.to_s << right
      end
      return( self )
    end

    def pad( padding )
      dup.pad!( padding )
    end

    def pad!( padding )
      padding.top.times { unshift( Line('') ) }
      padding.bottom.times { push( Line('') ) }
      w = width
      for line in self
        line.left!( w )
        line.pad!( padding.left, padding.right )
      end
      self
    end

    def reflow( paragraph_style = true )
      if paragraph_style
        cursor, new = 0, self.class.new
        text = self.to_s
        while text =~ /\n\s*\n/
          before, text = $`, $'
          new << `#{ before.gsub!( /[ \t]*\n/, ' ' ) || before }`
          new << ``
        end
        new << `#{ text.gsub!( /[ \t]*\n/, ' ' ) || text }`
        return( new )
      else
        text = self.to_s
        text.strip!
        text.gsub!( /\s+/, ' ' )
        self.class.new( text )
      end
    end

    def reflow!( paragraph_style = true )
      replace( reflow( paragraph_style ) )
    end

    def wrap( width )
      reflow.inject( self.class.new ) do | wrapped, line |
        wrapped.concat( line.wrap( width ) )
      end
    end

    def to_s
      join( $/ )
    end

    def uniform?
      @@uniform.fetch( hash ) do | h |
        @@uniform[ h ] = all? { | l | l.width == width }
      end
    end

    def valign!( alignment, h, filler = ''  )
      filler = Line( filler )
      h > height or return( self )
      case alignment
      when :top
        fill( filler, height, h - height )
      when :bottom
        ( h - height ).times { unshift( filler ) }
      when :center
        even, odd = ( h - height ).divmod( 2 )
        even.times { push( filler ); unshift( filler ) }
        odd == 1 and push( filler )
      end
      return( self )
    end

    def width
      @@width[ hash ] ||= ( map { | line | line.width }.max || 0 )
    end

    alias height length
    alias | juxtapose
    def `(str) #` # comment here cos my editor's colorizing freaks out
      SingleLine.new( str )
    end
  end

end