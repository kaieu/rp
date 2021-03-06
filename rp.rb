#!/usr/bin/env ruby

require 'optparse'

class Evaluator
  def initialize
    @stack = []
  end

  def pop(n)
    case n
    when Integer
      @stack.pop n
    when :START
      if spos = @stack.rindex(:START)
        ret = @stack[spos+1..-1]
        @stack.pop @stack.size - spos
      else
        ret = @stack.pop(@stack.size)
      end
      ret
    end
  end

  def exec(symbol)
    case symbol
    # binary operators
    when :+, :-, :*, :/
      a, b = pop(2)
      @stack << a.send(symbol, b)
    when :print
      puts pop(:START).join(" ")
    when :input
      print ">"
      STDOUT.flush
      @stack << gets.chomp
    when Symbol
      frame = pop(:START)
      frame.first.send symbol, *frame[1..-1]
    end
  end

  def evaluate(token)
    run_at_end = false
    if /\.$/ =~ token
      run_at_end = true
      token.chomp! "."
      return if token.empty?
    end
    case token
    when /^\d+$/ # integer
      @stack << $&.to_i
    when /^\d+\.\d+$/ # float
      @stack << $&.to_f
    when ":"
      @stack << :START
    when /^[\-\+\*\/\%\!]$/ # operator call
      exec $&.to_sym
    when /^"(\w+)"$/ # string
      @stack << $1
    when "STDOUT", "STDIN", "STDERR"
      @stack << Object.const_get(token.to_sym)
    when /^\w+$/ # procedure call
      exec $&.to_sym
    end
  rescue
    STDERR.puts "error in #{token}"
    raise
  end

  def eval_line(line)
    line.split(/\s+/).each do |t|
      evaluate t
    end
  end

  def show_stack
    puts @stack.join(" ")
  end
end

opts = {}
OptionParser.new do |op|
  op.on("-e script") {|s| opts[:script] = s}
  op.parse!
end

srcfile = ARGV.shift

ev = Evaluator.new

if s = opts[:script]
  ev.eval_line s
elsif srcfile
  File.open(srcfile) do |f|
    f.each_line do |l|
      ev.eval_line l
    end
  end
else
  ARGF.each_line do |l|
    ev.eval_line l
  end
end
  
ev.show_stack

# vim:set ts=2 sw=2 et:
