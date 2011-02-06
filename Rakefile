require 'rubygems'
require 'rake'
require 'echoe'

Echoe.new('easyredis','0.0.2') do |p|
  p.description = "simple framework designed to make using redis as a database simpler"
  p.url = "https://github.com/alecbenzer/easyredis"
  p.author = "Alec Benzer"
  p.email = "alecbezer @nospam@ gmail.com"
  p.ignore_pattern = ["*.rdb"]
  p.development_dependencies = ["redis >=2.1.1","activesupport >=3.0.0"]
end


require 'benchmark'
require './tests/test'

def rand_name
  length = 2
  chars = []
  length.times { chars << (rand(26) + 65).chr }
  chars.join
end


namespace :bm do
  task :clear do
    puts "destroying #{Man.count} previous entries"
    Benchmark.bm do |bm|
      bm.report { Man.destroy_all }
    end
  end

  task :add do
    count = ENV["count"] ? ENV["count"].to_i : 25000
    puts "adding #{count} new entries"
    time = Benchmark::Tms.new
    count.times do
      name = rand_name
      age = rand(100)
      time += Benchmark.measure { m = Man.new ; m.name = name ; m.age = age }
    end
    puts time.format
  end

  task :populate => [:clear, :add]

  task :search do
    puts "searching #{Man.count} entries by a particular name"
    name = Man.rand.name
    Benchmark.bm do |bm|
      bm.report { Man.search_by(:name,name) }
    end
  end

  task :singlesearch do
    puts "seaching #{Man.count} entries by a particular age"
    age = rand(100)
    Benchmark.bm(13) do |bm|
      bm.report("Man#search") { Man.search(:age => age) }
      bm.report("Man#search_by") { Man.search_by(:age,age) }
    end
  end

  task :multisearch do
    man = Man.rand
    name = man.name
    age = man.age
    count = 0
    time = Benchmark.measure { count = Man.search(:name => name, :age => age).size }
    puts "retrived #{count} out of #{Man.count} entries in:"
    puts time.format
  end

  task :find do
    puts "finding one of #{Man.count} entries by name"
    name = Man.rand.name
    Benchmark.bm do |bm|
      bm.report { Man.find_by(:name,name) }
    end
  end

end
