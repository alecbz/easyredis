require 'rubygems'
#Gem::manage_gems
require 'rake/gempackagetask'

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
