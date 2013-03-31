#!/usr/bin/env ruby

RubyVM::InstructionSequence.compile_option = {
  :tailcall_optimization => true,
  :trace_instruction => false
}

# RubyVM::InstructionSequence.new(<<-EOF).eval

require 'prime'

def memo_proc(&proc)
  already_run = false
  result = false
  lambda do
    if already_run
      result
    else
      result = proc.call
      already_run = true
      result
    end
  end
end

class Stream
  def initialize(first, &rest)
    @first = first
    @rest = memo_proc(&rest)
  end

  attr_reader :first

  def rest
    @rest.call
  end

  def at(n)
    if n == 0
      first
    else
      rest.at(n - 1)
    end
  end

  def select(&pred)
    if pred.call(first)
      Stream.new(first) { rest.select(&pred) }
    else
      rest.select(&pred)
    end
  end

  def map(&proc)
    Stream.new(proc.call(first)) do
      if rest == []
        []
      else
        rest.map(&proc)
      end
    end
  end

  def each(&proc)
    proc.call(first)
    rest.each(&proc)
  end

  def reduce(initial, &proc)
    rest.reduce(proc.call(initial, first), &proc)
  end

  def drop(n)
    if n < 1
      self
    else
      rest.drop(n - 1)
    end
  end

  def take(n)
    if n < 1
      []
    elsif n == 1
      Stream.new(first) { [] }
    else
      Stream.new(first) { rest.take(n - 1) }
    end
  end

  def display
    each { |x| puts x }
  end
end

def stream_enumerate_interval(low, high)
  if low > high
    []
  else
    Stream.new(low) { stream_enumerate_interval(low + 1, high) }
  end
end

def prime_stream_enumerate_interval(low, high)
  stream_enumerate_interval(low, high).select(&:prime?)
end

def integers_starting_from(n)
  Stream.new(n) { integers_starting_from(n + 1) }
end

def integers
  integers_starting_from(1)
end

def no_sevens
  integers.select { |i| i % 7 > 0 }
end

def fibgen(a, b)
  Stream.new(a) { fibgen(b, a + b) }
end

def fibs
  fibgen(0, 1)
end

def sieve(stream)
  Stream.new(stream.first) do
    sieve(stream.rest.select { |x| x % stream.first > 0 })
  end
end

def primes
  sieve(integers_starting_from(2))
end

def stream_map(*streams, &proc)
  if streams.first == []
    []
  else
    Stream.new(proc.call(*streams.map(&:first))) do
      stream_map(*streams.map(&:rest), &proc)
    end
  end
end

def add_streams(*streams)
  stream_map(*streams) do |*args|
    puts '+ ' + args.join(',')
    args.reduce(&:+)
  end
end

ones = Stream.new(1) { ones }

integers = Stream.new(1) { add_streams(ones, integers) }

fibs = Stream.new(0) do
  Stream.new(1) do
    add_streams(fibs.rest, fibs)
  end
end

primes = Stream.new(2) { integers_starting_from(3).select(&:prime?) }

def prime?(n)
  iter = -> (ps) do
    if ps.first**2 > n
      true
    elsif n % ps.first == 0
      false
    else
      iter(ps.rest)
    end
  end
  iter(primes)
end

if __FILE__ == $0
  puts prime_stream_enumerate_interval(10000, 1000000).reduce(0, &:+)
  no_sevens.take(100).display
  puts integers.take(10).reduce(0, &:+)
  add_streams(integers.take(10), integers.take(10)).display
  integers.take(10).display
  fibs.take(6).display
  primes.take(2000).display
end
