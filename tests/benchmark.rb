require './tests/test'
require 'benchmark'

$names = ["Bill","Bob","John","Jack","Alec","Mark","Nick","Evan","Eamon","Joe","Vikram"]

def rand_name
  $names[rand*$names.size]
end

$count = 0
$num_add = ARGV[0] ? ARGV[0].to_i : 50000 

puts "counting entries"
Benchmark.bm(7) do |bm|
  bm.report { $count = Man.count }
end
puts

puts "destroying #{$count} previous entries"
Benchmark.bm(7) do |bm|
  bm.report { Man.destroy_all }
end
puts

puts "adding #{$num_add} new entries"
Benchmark.bm(7) do |bm|
  bm.report { $num_add.times { m = Man.new ; m.name = rand_name } }
end
puts

puts "sorting by name"
Benchmark.bm(7) do |bm|
  bm.report("ruby:") { Man.all.sort_by { |m| m.name } }
  bm.report("redis:") { Man.sort_by(:name) }
end
puts

puts "finding all entries by a particular name"
Benchmark.bm(7) do |bm|
  name = rand_name
  bm.report("ruby:") { Man.all.select {|m| m.name == name} }
  bm.report("redis:") { Man.search_by(:name,name) }
end
puts
