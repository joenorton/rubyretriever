require 'benchmark'

array = (1..1000000).map {(0...40).map { ('a'..'z').to_a[rand(26)] }.join}

Benchmark.bmbm do |x|
  x.report("uniq!_and_sort!") { array.uniq!;array.sort_by!{|x| x.length} }
  x.report("sort!_and_uniq!")  { array.sort_by! {|x| x.length};array.uniq!  }
  x.report("uniq!")  { array.uniq! }
  x.report("sort!")  { array.sort!  }
end