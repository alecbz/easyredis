require 'rubygems'
require 'benchmark'
require 'rake/gempackagetask'
require './tests/test'

spec = Gem::Specification.new do |s|
  s.platform = Gem::Platform::RUBY
  s.name = "easyredis"
  s.version = "0.0.1"
  s.author = "Alec Benzer"
  s.email = "alecbenzer@gmail.com"
  s.summary = "simple framework designed to make using redis as a database simpler"
  s.files = FileList['lib/*.rb','test/*'].to_a
  s.require_path = "lib"
  s.test_files = Dir.glob('tests/*.rb')
  s.has_rdoc = false
  s.add_dependency("redis")
  s.add_dependency("active_support/inflector")
end

Rake::GemPackageTask.new(spec) do |pkg|
  pkg.need_tar = true
end

task :default => "pkg/#{spec.name}-#{spec.version}.gem" do
  puts "generated latest version"
end

$names = ["Bill","Bob","John","Jack","Alec","Mark","Nick","Evan","Eamon","Joe","Vikram"]

def rand_name
  $names[rand*$names.size]
end

namespace :bm do
  task :clear do
    count = Man.count

    puts "destroying #{$count} previous entries"
    Benchmark.bm(7) do |bm|
      bm.report { Man.destroy_all }
    end
  end

  task :add do
    count = ENV["count"] ? ENV["count"].to_i : 25000
    puts "adding #{count} new entries"
    Benchmark.bm(7) do |bm|
      bm.report { count.times { m = Man.new ; m.name = rand_name } }
    end
  end

  task :populate => [:clear, :add]

  task :sort do
    puts "sorting by name"
    Benchmark.bm(7) do |bm|
      bm.report("ruby:") { Man.all.sort_by { |m| m.name } }
      bm.report("redis:") { Man.sort_by(:name) }
    end
  end

  task :search do
    puts "finding all entries by a particular name"
    Benchmark.bm(7) do |bm|
      name = rand_name
      bm.report("ruby:") { Man.all.select {|m| m.name == name} }
      bm.report("redis:") { Man.search_by(:name,name) }
    end
  end

  task :find do
    puts "finding on entry by name"
    Benchmark.bm(7) do |bm|
      name = rand_name
      bm.report("redis:") { Man.find_by(:name,name) }
    end
  end

end
