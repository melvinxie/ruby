#!/usr/bin/env ruby

RubyVM::InstructionSequence.compile_option = {
  :tailcall_optimization => true,
  :trace_instruction => false
}

# RubyVM::InstructionSequence.new(<<-EOF).eval

def memo_proc(&proc)
  already_run = false
  result = nil
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
  def initialize(first=nil, &rest)
    @first = first
    @rest = block_given? ? memo_proc(&rest) : lambda {}
  end

  attr_reader :first

  def rest
    @rest.call
  end

  def empty?
    first.nil?
  end

  def at(n)
    if empty?
      nil
    elsif n == 0
      first
    else
      rest.at(n - 1)
    end
  end

  def display
    each { |e| puts e }
  end

  def drop(n)
    if empty? or n < 1
      self
    else
      rest.drop(n - 1)
    end
  end

  def each(&proc)
    unless empty?
      proc.call(first)
      rest.each(&proc)
    end
    self
  end

  def map(&proc)
    if empty?
      self
    else
      Stream.new(proc.call(first)) { rest.map(&proc) }
    end
  end

  def reduce(initial, &proc)
    if empty?
      initial
    else
      rest.reduce(proc.call(initial, first), &proc)
    end
  end

  def select(&pred)
    if empty?
      self
    elsif pred.call(first)
      Stream.new(first) { rest.select(&pred) }
    else
      rest.select(&pred)
    end
  end

  def take(n)
    if empty? or n < 1
      Stream.new
    else
      Stream.new(first) { rest.take(n - 1) }
    end
  end
end

def enumerate_interval(low, high)
  if low > high
    Stream.new
  else
    Stream.new(low) { enumerate_interval(low + 1, high) }
  end
end

def integers_starting_from(n)
  Stream.new(n) { integers_starting_from(n + 1) }
end

def no_sevens
  integers_starting_from(1).select { |i| i % 7 > 0 }
end

def fibgen(a, b)
  Stream.new(a) { fibgen(b, a + b) }
end

def sieve(stream)
  Stream.new(stream.first) do
    sieve(stream.rest.select { |e| e % stream.first > 0 })
  end
end

def prime_sieve
  sieve(integers_starting_from(2))
end

def stream_map(*streams, &proc)
  if streams.first.empty?
    Stream.new
  else
    Stream.new(proc.call(*streams.map(&:first))) do
      stream_map(*streams.map(&:rest), &proc)
    end
  end
end

def add_streams(*streams)
  stream_map(*streams) { |*args| args.reduce(&:+) }
end

ones = Stream.new(1) { ones }

integers = Stream.new(1) { add_streams(ones, integers) }

fibs = Stream.new(0) { Stream.new(1) { add_streams(fibs.rest, fibs) } }

def iter_primes(primes, n)
  iter = lambda do |ps|
    if ps.first**2 > n
      true
    elsif n % ps.first == 0
      false
    else
      iter.call(ps.rest)
    end
  end
  iter.call(primes)
end

primes = Stream.new(2) do
  integers_starting_from(3).select { |n| iter_primes(primes, n) }
end

is_prime = lambda do |n|
  iter_primes(primes, n)
end

prime_enumerate_interval = lambda do |low, high|
  enumerate_interval(low, high).select(&is_prime)
end

if __FILE__ == $0
  puts prime_stream_enumerate_interval(10000, 1000000).reduce(0, &:+)
  no_sevens.take(100).display
  puts integers.take(10).reduce(0, &:+)
  add_streams(integers.take(10), integers.take(10)).display
  integers.take(10).display
  fibs.take(2000).display
  primes.take(2000).display
  prime_enumerate_interval.call(3, 20).display
end
