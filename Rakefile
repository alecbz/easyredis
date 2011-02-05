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

$names = ["Bill","Bob","John","Jack","Alec","Mark","Nick","Evan","Eamon","Joe","Vikram"]

def rand_name
  $names[rand*$names.size]
end

namespace :bm do
  task :clear do
    count = Man.count

    puts "destroying #{$count} previous entries"
    Benchmark.bm do |bm|
      bm.report { Man.destroy_all }
    end
  end

  task :add do
    count = ENV["count"] ? ENV["count"].to_i : 25000
    puts "adding #{count} new entries"
    Benchmark.bm do |bm|
      bm.report { count.times { m = Man.new ; m.name = rand_name ; m.age = (rand*100).to_i} }
    end
  end

  task :populate => [:clear, :add]

  task :sort do
    puts "sorting #{Man.count} entries by name"
    Benchmark.bm do |bm|
      #bm.report("ruby:") { Man.all.sort_by { |m| m.name } }
      #bm.report("redis:") { Man.sort_by(:name) }
      bm.report { Man.sort_by(:name) }
    end
  end

  task :search do
    puts "searching #{Man.count} entries by a particular name"
    Benchmark.bm do |bm|
      name = rand_name
      #bm.report("ruby:") { Man.all.select {|m| m.name == name} }
      #bm.report("redis:") { Man.search_by(:name,name) }
      bm.report { Man.search_by(:name,name) }
    end
  end

  task :find do
    puts "finding one of #{Man.count} entry by name"
    Benchmark.bm do |bm|
      name = rand_name
      #bm.report("redis:") { Man.find_by(:name,name) }
      bm.report { Man.find_by(:name,name) }
    end
  end

end

task :doc do
  puts `rdoc lib/ --title "EasyRedis"`
end
