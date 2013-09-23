#!/usr/bin/ruby
# encoding: utf-8

module MonoclePrint
module Linkable
  include Enumerable
  attr_accessor :before, :after
  protected :before=, :after=
  
  def each
    block_given? or return( enum_for( :each ) )
    node = self
    begin
      yield( node )
      node = node.after
    end while( node )
  end
  
  def first?
    @before.nil?
  end
  
  def last?
    @after.nil?
  end
  
  def unlink
    @before and @before.after = nil
    @before = nil
    return( self )
  end
  
  def <<( item )
    after, @after, item.before = @after, item, self
    after ? item.link( after ) : item
  end
  
  alias link <<
  
end

class LinkedList
  
  def initialize
    @head = Node.new
    @tail = Node.new
    @lookup = Hash.new
  end
  
end


end
