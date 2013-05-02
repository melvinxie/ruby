#!/usr/bin/env ruby

require './stream'

def enumerate_interval(low, high)
  low > high ? Stream.new :
               Stream.new(low) { enumerate_interval(low + 1, high) }
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

@primes = Stream.new(2) { integers_starting_from(3).select(&method(:prime?)) }

def prime?(n)
  iter = -> ps do
    if ps.first**2 > n
      true
    elsif n % ps.first == 0
      false
    else
      iter.call(ps.rest)
    end
  end
  iter.call(@primes)
end

def prime_enumerate_interval(low, high)
  enumerate_interval(low, high).select(&method(:prime?))
end

def sqrt_improve(guess, x)
  (guess + x / guess) / 2
end

def sqrt_stream(x)
  guesses = Stream.new(1.0) { guesses.map { |guess| sqrt_improve(guess, x) } }
end

def pi_summands(n)
  Stream.new(1.0 / n) { pi_summands(n + 2).map(&:-@) }
end

def pi_stream
  pi_summands(1).partial_sums.scale(4)
end

def euler_transform(s)
  s0 = s.first
  s1 = s.at(1)
  s2 = s.at(2)
  first = s2 - ((s2 - s1)**2 / (s0 - 2 * s1 + s2))
  Stream.new(first) { euler_transform(s.rest) }
end

def make_tableau(s, &transform)
  Stream.new(s) { make_tableau(transform.call(s), &transform) }
end

def accelerated_sequence(s, &transform)
  make_tableau(s, &transform).map(&:first)
end

def pairs(s, t)
  Stream.new([s.first, t.first]) do
    Stream.interleave(t.rest.map { |x| [s.first, x] },
                      pairs(s.rest, t.rest))
  end
end

def integral(integrand, initial, dt)
  int = Stream.new(initial) { Stream.add(integrand.scale(dt), int) }
end

def solve(f, y0, dt)
  y = integral(promise { y.map(&f) }, y0, dt)
end

def random_numbers
  Stream.new(rand(2**31)) { random_numbers }
end

def gcd(a, b)
  b == 0 ? a : gcd(b, a % b)
end

def cesaro
  random_numbers.map_successive_pairs { |r1, r2| gcd(r1, r2) == 1 }
end

def monte_carlo(experiments, passed, failed)
  next_try = -> passed, failed do
    Stream.new(passed.to_f / (passed + failed)) do
      monte_carlo(experiments.rest, passed, failed)
    end
  end
  experiments.first ? next_try.call(passed + 1, failed) :
                      next_try.call(passed, failed + 1)
end

def monte_carlo_pi
  monte_carlo(cesaro, 0, 0).map { |p| (6 / p)**0.5 }
end

if __FILE__ == $0
  puts Stream.new(1) { Stream.new(2) { Stream.new(3) } }.to_a == [1, 2, 3]

  puts no_sevens.take(10).to_a == [1, 2, 3, 4, 5, 6, 8, 9, 10, 11]
  puts integers.take(10).reduce(&:+) == 55
  puts Stream.add(integers.take(10), integers.take(10)).to_a ==
       [2, 4, 6, 8, 10, 12, 14, 16, 18, 20]
  puts integers.take(10).to_a == [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
  puts fibs.take(10).to_a == [0, 1, 1, 2, 3, 5, 8, 13, 21, 34]

  puts @primes.take(10).to_a == [2, 3, 5, 7, 11, 13, 17, 19, 23, 29]
  puts prime_enumerate_interval(10, 30).to_a == [11, 13, 17, 19, 23, 29]
  puts prime_enumerate_interval(10000, 40000).reduce(&:+) == 73434270

  puts sqrt_stream(2).take(5).to_a ==
       [1.0, 1.5, 1.4166666666666665, 1.4142156862745097, 1.4142135623746899]
  puts euler_transform(pi_stream).take(5).to_a ==
       [3.166666666666667, 3.1333333333333337, 3.1452380952380956,
        3.13968253968254, 3.1427128427128435]
  puts accelerated_sequence(pi_stream, &method(:euler_transform)).take(5)
       .to_a == [4.0, 3.166666666666667, 3.142105263157895, 3.141599357319005,
                 3.1415927140337785]

  puts pairs(integers, integers).take(5).to_a ==
       [[1, 1], [1, 2], [2, 2], [1, 3], [2, 3]]
  puts pairs(integers, integers).select { |i, j| prime?(i + j) }.take(5)
       .to_a == [[1, 1], [1, 2], [2, 3], [1, 4], [1, 6]]

  puts solve(lambda { |y| y }, 1, 0.001).at(1000) == 2.716923932235896

  puts monte_carlo_pi.at(1000)
end
