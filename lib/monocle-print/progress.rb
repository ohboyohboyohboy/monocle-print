#!/usr/bin/ruby
# encoding: utf-8

module MonoclePrint
class Progress < OutputDevice
  
  attr_accessor :position, :total, :bar_color
  attr_reader :output, :title
  attr_writer :width
  
  def self.enumerate( collection, method = :each, *args )
    block_given? or return enum_for( :enumerate, collection, method, *args )
    #options = Hash === args.last ? args.pop : {}
    
    #method = options.fetch( :method, nil )
    #if method.nil? and Symbol === args.first
    #  method, *args = args
    #else
    #  method ||= :each
    #end
    
    #size = options[ :size ]
    #size ||= options.fetch( :length ) do
    #  collection.length rescue collection.size
    #end
    size = collection.length rescue collection.size
    
    enum = collection.enum_for( method, *args )
    run( size ) do | bar |
      for item in enum
        v = yield( item, bar )
        bar.step
        v
      end
    end
  end
  
  def self.run( total, options = {} )
    bar = new( total, options )
    yield( bar )
  ensure
    bar.clear_line
  end
  
  def initialize( total, options = {} )
    @total = total.to_i.at_least( 1 )
    @position = 0
    @title = Line( options[ :title ].to_s )
    @limit = @width = @time = @next_time = nil
    @bar_color = options.fetch( :bar_color, :red )
    @text_color = options.fetch( :text_color, :black )
    @progress = -1
    @draw = true
    super( options.fetch( :output, $stderr ), options )
  end
  
  def stage( title, limit = @total - @position, absolute = false )
    limit += @position unless absolute
    self.title = title
    limit( limit ) do
      return( yield( self ) )
    end
  end
  
  def step( inc = 1 )
    limit = @limit || @total
    @position = ( @position + inc ).at_most( limit )
    draw? and display
  end
  
  def draw?
    progress = @position * 100 / @total
    if @progress != progress
      @progress = progress
      @draw = true
    end
    
    return @draw
  end
  
  def limit( l = nil )
    unless l.nil?
      begin
        before, @limit = @limit, l.to_i.at_most( @total )
        yield( self )
      ensure
        self.limit = before
      end
    end
    return( @limit )
  end
  
  def limit=( l )
    @limit = l.to_i.at_most( @total )
  end
  
  def start_time
    @start_time ||= Time.now
  end
  
  def duration
    Time.now - start_time
  end
  
  def title= t
    title = Line( t.to_s )
    if title != @title
      @title = title
      @draw = true
    end
  end
  
  def display
    return!
    
    hour, r  = time_remaining.divmod( 3600 )
    min, sec = r.divmod( 60 )
    sec = sec.round
    eta = Line( ' %02i:%02i:%02i' % [ hour, min, sec ] )
    
    center_width = 6
    right_width  = ( width - center_width ) / 2
    left_width   = width - center_width - right_width
    
    center = ( @progress.to_s << '%' ).center( 6 ) # " ___% "
    left   = title.align( :left, left_width ).truncate!( left_width, '...' )
    right  = eta.align( :right, right_width )
    
    bar = left << center << right
    
    color_code = ''
    @bar_color  and color_code << ansi_color( ?b, @bar_color )
    @text_color and color_code << ansi_color( ?f, @text_color )
    
    unless color_code.empty?
      fill_point = bar.char_byte( width * @position / @total )
      bar.insert( fill_point, "\e[0m" )
      bar.insert( 0, color_code )
    end
    
    print( bar )
    @draw = false
    self
  end
  
  def title_width
    width * 0.3
  end
  
  def reset
    @position = 0
    @limit = nil
    @start_time = nil
  end
  
  def to_s
    title_width = ( width * 0.4 ).round
    title = @title.align( :center, title_width )[ 0, title_width ]
    
    hour, r  = time_remaining.divmod( 3600 )
    min, sec = r.divmod( 60 )
    sec = sec.round
    eta = '%02i:%02i:%02i' % [ hour, min, sec ]
    
    fill_width = width - title_width - eta.length - 9
    filled = ( fill_width * @position / @total ).round
    title << ' |' << ( '*' * filled ).ljust( fill_width ) <<
      '| ' << ( '%3i%% ' % progress ) << eta
  end
  
  def progress
    @position * 100 / @total
  end
  
  def time_remaining
    @position < 2 and return( 0 )
    sec_per_step = duration / @position 
    ( @total - @position ) * sec_per_step
  end
  
  alias wipe clear_line
  
  def hide
    wipe
    return yield
  ensure
    display
  end
  
  
end
end
