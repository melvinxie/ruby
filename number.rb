#!/usr/bin/env ruby

require './stream'

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

ones = Stream.new(1) { ones }

integers = Stream.new(1) { Stream.add(ones, integers) }

fibs = Stream.new(0) { Stream.new(1) { Stream.add(fibs.rest, fibs) } }

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

no_sevens.take(100).display
puts integers.take(10).reduce(0, &:+)
Stream.add(integers.take(10), integers.take(10)).display
integers.take(2000).display
fibs.take(2000).display
primes.take(2000).display
prime_enumerate_interval.call(1, 200).display
puts prime_enumerate_interval.call(10000, 40000).reduce(0, &:+)
