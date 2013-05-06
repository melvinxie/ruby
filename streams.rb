#!/usr/bin/env ruby

require 'lazy_stream'
require 'promise'

def enumerate_interval(low, high)
  low > high ? lazy_stream :
               lazy_stream(low) { enumerate_interval(low + 1, high) }
end

def integers_starting_from(n)
  lazy_stream(n) { integers_starting_from(n + 1) }
end

def no_sevens
  integers_starting_from(1).select { |i| i % 7 > 0 }
end

def fibgen(a, b)
  lazy_stream(a) { fibgen(b, a + b) }
end

def sieve(stream)
  lazy_stream(stream.first) do
    sieve(stream.rest.select { |x| x % stream.first > 0 })
  end
end

def prime_sieve
  sieve(integers_starting_from(2))
end

ones = lazy_stream(1) { ones }

integers = lazy_stream(1) { LazyStream.add(ones, integers) }

fibs = lazy_stream(0) { lazy_stream(1) { LazyStream.add(fibs.rest, fibs) } }

@primes = lazy_stream(2) { integers_starting_from(3).select(&method(:prime?)) }

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
  guesses = lazy_stream(1.0) { guesses.map { |guess| sqrt_improve(guess, x) } }
end

def pi_summands(n)
  lazy_stream(1.0 / n) { pi_summands(n + 2).map(&:-@) }
end

def pi_stream
  pi_summands(1).partial_sums.scale(4)
end

def euler_transform(s)
  lazy_stream(s[2] - ((s[2] - s[1])**2 / (s[0] - 2 * s[1] + s[2]))) do
    euler_transform(s.rest)
  end
end

def make_tableau(s, &transform)
  lazy_stream(s) { make_tableau(transform.call(s), &transform) }
end

def accelerated_sequence(s, &transform)
  make_tableau(s, &transform).map(&:first)
end

def pairs(s, t)
  lazy_stream([s.first, t.first]) do
    LazyStream.interleave(t.rest.map { |x| [s.first, x] },
                      pairs(s.rest, t.rest))
  end
end

def integral(integrand, initial, dt)
  int = lazy_stream(initial) { LazyStream.add(integrand.scale(dt), int) }
end

def solve(f, y0, dt)
  y = integral(promise { y.map(&f) }, y0, dt)
end

def random_numbers
  lazy_stream(rand(2**31)) { random_numbers }
end

def gcd(a, b)
  b == 0 ? a : gcd(b, a % b)
end

def cesaro
  random_numbers.map_successive_pairs { |r1, r2| gcd(r1, r2) == 1 }
end

def monte_carlo(experiments, passed, failed)
  next_try = -> passed, failed do
    lazy_stream(passed.to_f / (passed + failed)) do
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
  puts lazy_stream(1) { lazy_stream(2) { lazy_stream } }.to_a == [1, 2]
  puts lazy_stream(1) { lazy_stream(2) { lazy_stream(3) } }.to_a == [1, 2, 3]

  puts no_sevens.take(10).to_a == [1, 2, 3, 4, 5, 6, 8, 9, 10, 11]
  puts integers.take(10).reduce(&:+) == 55
  puts LazyStream.add(integers.take(10), integers.take(10)).to_a ==
       [2, 4, 6, 8, 10, 12, 14, 16, 18, 20]
  puts integers.take(10).to_a == [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
  puts fibs.take(10).to_a == [0, 1, 1, 2, 3, 5, 8, 13, 21, 34]

  puts @primes.take(10).to_a == [2, 3, 5, 7, 11, 13, 17, 19, 23, 29]
  puts prime_enumerate_interval(10, 30).to_a == [11, 13, 17, 19, 23, 29]
  puts prime_enumerate_interval(10000, 40000).reduce(&:+) == 73434270

  puts sqrt_stream(2).take(5).to_a ==
       [1.0, 1.5, 1.4166666666666665, 1.4142156862745097, 1.4142135623746899]
  puts pi_stream.take(8).to_a ==
       [4.0, 2.666666666666667, 3.466666666666667, 2.8952380952380956,
        3.3396825396825403, 2.9760461760461765, 3.2837384837384844,
        3.017071817071818]
  puts euler_transform(pi_stream).take(8).to_a ==
       [3.166666666666667, 3.1333333333333337, 3.1452380952380956,
        3.13968253968254, 3.1427128427128435, 3.1408813408813416,
        3.142071817071818, 3.1412548236077655]
  puts accelerated_sequence(pi_stream, &method(:euler_transform)).take(8)
       .to_a == [4.0, 3.166666666666667, 3.142105263157895, 3.141599357319005,
                 3.1415927140337785, 3.1415926539752927, 3.1415926535911765,
                 3.141592653589778]

  puts pairs(integers, integers).take(5).to_a ==
       [[1, 1], [1, 2], [2, 2], [1, 3], [2, 3]]
  puts pairs(integers, integers).select { |i, j| prime?(i + j) }.take(5)
       .to_a == [[1, 1], [1, 2], [2, 3], [1, 4], [1, 6]]

  puts solve(lambda { |y| y }, 1, 0.001).at(1000) == 2.716923932235896

  puts monte_carlo_pi.at(1000)
end
