#!/usr/bin/ruby
# encoding: utf-8

module MonoclePrint
  VERSION = '0.6.1'

  def self.version
    VERSION
  end

  def self.included( kl )
    super
    kl.extend( self )
  end

  def self.library_path( *args )
    File.join( File.dirname( __FILE__ ), *args )
  end

  def self.stdout
    Output( $stdout )
  end

module_function

  def Line( obj )
    SingleLine === obj ? obj : SingleLine.new( obj.to_s )
  end

  def Output( dev )
    OutputDevice === dev ? dev : OutputDevice.new( dev )
  end

  def Text( obj )
    case obj
    when Text then obj
    when nil then Text.new( '' )
    else Text.new( obj.to_s )
    end
  end

  def Style( obj )
    Graphics === obj ? obj : Graphics::NAMED_STYLES[ obj.to_s ]
  end

  def Rectangle( obj )
    case obj
    when Rectangle then obj
    when Array then Rectangle.new( *obj )
    when Hash then Rectangle.create( obj )
    else Rectangle.new( obj )
    end
  end

end

$LOAD_PATH.unshift( MonoclePrint.library_path )

for f in Dir[ MonoclePrint.library_path( 'monocle-print', 'core-ext', '*.rb' ) ]
  require "monocle-print/core-ext/#{ File.basename( f, ".rb" ) }"
end

%w(
  utils presentation terminal-escapes
  atomic graphics output-device progress
  table list
).each do | lib |
  require "monocle-print/#{ lib }"
end