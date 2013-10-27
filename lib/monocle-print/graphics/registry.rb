#!/usr/bin/ruby
# encoding: utf-8
#
# author: Kyle Yetter
#

module MonoclePrint
module GraphicsRegistry
  ENV_KEY        = "MONOCLE_PRINT_STYLE"
  FALLBACK_STYLE = "single_line"

  attr_accessor :default_style

  def named_styles
    @named_styles ||= Hash.new { |h, k| h[ default_style ].dup }
  end

  def style?( name )
    named_styles.key?( name.to_s )
  end

  def style( name )
    named_styles[ name.to_s ]
  end

  def styles
    named_styles.keys
  end

  def default_style
    @default_style ||= detect_style_from_env
  end

  def default
    style( default_style )
  end

  def define( name, *parts )
    parts.map! { | p | Line( p ).freeze }
    name       = name.to_s
    definition = new( *parts ).freeze
    named_styles.store( name, definition )
    define_singleton_method( name ) { style( name ) }
    definition
  end

  private

  def detect_style_from_env
    default_style = ENV.fetch( ENV_KEY, FALLBACK_STYLE )
    unless style?( default_style )
      message = <<-END.gsub!( /^\s*\| ?/, '' ).strip!.gsub!( /\s+/, ' ' )
      | cannot set MonoclePrint's default graphics style
      | from the MONOCLE_PRINT_STYLE environment variable as `%s'
      | is not a known style; defaulting to `%s'
      END
      warn( message % [ default_style, FALLBACK_STYLE ] )
      default_style = FALLBACK_STYLE
    end
    default_style
  end
end
end