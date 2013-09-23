#!/usr/bin/ruby
# encoding: utf-8
#
# author: Kyle Yetter
#

$LOAD_PATH.unshift( "lib" )

require 'rubygems'
require 'hoe'
require 'monocle-print'

PACKAGE_NAME = File.basename( File.dirname( __FILE__ ) )

Rake.application.options.ignore_deprecate = true

Hoe.spec PACKAGE_NAME do
  developer( PACKAGE_NAME, 'kyle@ohboyohboyohboy.org' )
  self.version = MonoclePrint.version
end

