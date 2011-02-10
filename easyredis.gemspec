# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{easyredis}
  s.version = "0.0.5"

  s.required_rubygems_version = Gem::Requirement.new(">= 1.2") if s.respond_to? :required_rubygems_version=
  s.authors = ["Alec Benzer"]
  s.date = %q{2011-02-09}
  s.description = %q{framework designed to make using redis as a database simpler}
  s.email = %q{alecbezer @nospam@ gmail.com}
  s.extra_rdoc_files = ["LICENSE", "README.md", "lib/easyredis.rb"]
  s.files = ["LICENSE", "Manifest", "README.md", "Rakefile", "easyredis.gemspec", "lib/easyredis.rb", "tests/benchmark.rb", "tests/test.rb"]
  s.homepage = %q{https://github.com/alecbenzer/easyredis}
  s.rdoc_options = ["--line-numbers", "--inline-source", "--title", "Easyredis", "--main", "README.md"]
  s.require_paths = ["lib"]
  s.rubyforge_project = %q{easyredis}
  s.rubygems_version = %q{1.5.0}
  s.summary = %q{framework designed to make using redis as a database simpler}

  if s.respond_to? :specification_version then
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_development_dependency(%q<redis>, [">= 2.1.1"])
    else
      s.add_dependency(%q<redis>, [">= 2.1.1"])
    end
  else
    s.add_dependency(%q<redis>, [">= 2.1.1"])
  end
end
