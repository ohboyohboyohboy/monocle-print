#!/usr/bin/ruby
# encoding: utf-8

begin
  require 'io/console'
rescue LoadError
  # ignore
end

require 'delegate'
autoload :StringIO, 'stringio' unless defined?( StringIO )

module MonoclePrint
  VERSION = '1.0.3'

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

  def self.stdout( options = {}, &block )
    OutputDevice.stdout( options, &block )
  end

  def self.stderr( options = {}, &block )
    OutputDevice.stderr( options, &block )
  end

  def self.buffer( options = {}, &block )
    OutputDevice.buffer( options, &block )
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
    Graphics === obj ? obj : Graphics.style( obj )
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

%w(
  utils
  geometry
  presentation
  terminal-escapes
  atomic
  graphics
  output-device
  progress
  table
  list
).each { | lib | require "monocle-print/#{ lib }" }
