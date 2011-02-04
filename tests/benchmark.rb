require './tests/test'
require 'benchmark'

$names = ["Bill","Bob","John","Jack","Alec","Mark","Nick","Evan","Eamon","Joe","Vikram"]

def rand_name
  $names[rand*$names.size]
end

puts "destroying previous records"
Benchmark.bm(7) do |bm|
  bm.report { Man.destroy_all }
end
puts

puts "adding 25,000 men"
Benchmark.bm(7) do |bm|
  bm.report { 25000.times { m = Man.new ; m.name = rand_name } }
end
puts

puts "sorting by name"
Benchmark.bm(18) do |bm|
  bm.report("ruby sort_by:") { Man.all.sort_by { |m| m.name } }
  bm.report("easyredis sort_by:") { Man.sort_by(:name) }
end
puts

puts "finding all entries by name"
Benchmark.bm(20) do |bm|
  name = rand_name
  bm.report("ruby Array.select:") { Man.all.select {|m| m.name == name} }
  bm.report("easyredis search_by:") { Man.search_by(:name,name) }
end
puts
