#!/usr/bin/ruby
# encoding: utf-8
#

PROJECT_NAME = "monocle-print"

require_relative './lib/monocle-print'
require "rubygems"
require "hoe"

# Hoe.plugin :compiler
# Hoe.plugin :gem_prelude_sucks
# Hoe.plugin :inline
# Hoe.plugin :minitest
# Hoe.plugin :racc
# Hoe.plugin :rcov
Hoe.plugin :version
Hoe.plugins.delete(:test)

Hoe.spec PROJECT_NAME do
  developer( "Kyle Yetter", "kyle@ohboyohboyohboy.org")
  license "MIT" # this should match the license in the README
  
  self.version     = MonoclePrint::VERSION
  self.readme_file = 'README.txt'
end
