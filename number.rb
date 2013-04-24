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
    sieve(stream.rest.select { |x| x % stream.first > 0 })
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

def sqrt_improve(guess, x)
  (guess + x / guess) / 2
end

def sqrt(x)
  guesses = Stream.new(1.0) do
    guesses.map { |guess| sqrt_improve(guess, x) }
  end
  guesses
end

def pi_summands(n)
  Stream.new(1.0 / n) { pi_summands(n + 2).map(&:-@) }
end

def pi_stream
  pi_summands(1).partial_sums.scale(4)
end

euler_transform = lambda do |s|
  s0 = s.first
  s1 = s.at(1)
  s2 = s.at(2)
  s3 = s2 - ((s2 - s1)**2 / (s0 - 2 * s1 + s2))
  Stream.new(s3) { euler_transform.call(s.rest) }
end

def make_tableau(transform, s)
  Stream.new(s) { make_tableau(transform, transform.call(s)) }
end

def accelerated_sequence(transform, s)
  make_tableau(transform, s).map(&:first)
end


no_sevens.take(10).display
# 1 2 3 4 5 6 8 9 10 11

puts integers.take(10).reduce(&:+)
# 55

Stream.add(integers.take(10), integers.take(10)).display
# 2 4 6 8 10 12 14 16 18 20

integers.take(10).display
# 1 2 3 4 5 6 7 8 9 10

fibs.take(10).display
# 0 1 1 2 3 5 8 13 21 34

primes.take(10).display
# 2 3 5 7 11 13 17 19 23 29

prime_enumerate_interval.call(10, 30).display
# 11 13 17 19 23 29

puts prime_enumerate_interval.call(10000, 40000).reduce(&:+)
# 73434270

sqrt(2).take(5).display
# 1.0
# 1.5
# 1.4166666666666665
# 1.4142156862745097
# 1.4142135623746899

euler_transform.call(pi_stream).take(5).display
# 3.166666666666667
# 3.1333333333333337
# 3.1452380952380956
# 3.13968253968254
# 3.1427128427128435

accelerated_sequence(euler_transform, pi_stream).take(5).display
# 4.0
# 3.166666666666667
# 3.142105263157895
# 3.141599357319005
# 3.1415927140337785
