require 'rubygems'
require 'rake'
require 'echoe'

Echoe.new('easyredis','0.0.5') do |p|
  p.description = "framework designed to make using redis as a database simpler"
  p.url = "https://github.com/alecbenzer/easyredis"
  p.author = "Alec Benzer"
  p.email = "alecbezer @nospam@ gmail.com"
  p.ignore_pattern = ["*.rdb"]
  p.development_dependencies = ["redis >=2.1.1"]
end


require 'benchmark'
require './tests/man'

def rand_name(length=2)
  chars = []
  length.times { chars << (rand(26) + 65).chr }
  chars.join
end


namespace :bm do
  task :clear do
    puts "destroying #{Man.count} previous entries"
    time = Benchmark.measure { Man.destroy_all }
    puts time.format
  end

  task :add do
    count = ENV["count"] ? ENV["count"].to_i : 25000
    puts "adding #{count} new entries"
    time = Benchmark::Tms.new
    length = Math.log(3*count,26).round
    count.times do
      name = rand_name(length)
      age = rand(100)
      time += Benchmark.measure { m = Man.new ; m.name = name ; m.age = age }
    end
    puts time.format
  end

  task :populate => [:clear, :add]

  task :search do
    puts "searching #{Man.count} entries by a particular name"
    name = Man.rand.name
    count = -1
    time = Benchmark.measure { count = Man.search_by(:name,name).count }
    puts "retrived #{count} records in:"
    puts (time*1000).format
  end

  task :singlesearch do
    puts "seaching #{Man.count} entries by a particular age"
    puts "NOTE: this metric is only relevant if Model#search is not detecting single-field searches and using Model#search_by"
    age = rand(100)
    t1 = Benchmark.measure { Man.search(:age => age) }
    t2 = Benchmark.measure { Man.search_by(:age,age) }
    puts "Model#search:"
    puts (t1*1000).format
    puts "Model#search_by:"
    puts (t2*1000).format
    puts "search is #{((t1.real/t2.real) - 1)*100}% slower"
  end

  task :multisearch do
    man = Man.rand
    name = man.name
    age = man.age
    count = 0
    time = Benchmark.measure { count = Man.search(:name => name, :age => age).size }
    puts "retrived #{count} out of #{Man.count} entries in:"
    puts (time*1000).format
  end

  task :find do
    puts "finding one of #{Man.count} entries by name"
    name = Man.rand.name
    time = Benchmark.measure { Man.find_by(:name,name) }
    puts (time*1000).format
  end

end
