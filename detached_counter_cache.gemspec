# Provide a simple gemspec so you can easily use your enginex
# project in your rails apps through git.
Gem::Specification.new do |s|
  s.add_development_dependency("mocha")
  s.add_development_dependency("pg", "~> 0.10.0")
  s.add_runtime_dependency("activerecord", "~> 3.0.8")
  s.name = "detached_counter_cache"
  s.summary = "Stores cached counters in a separate table"
  s.description = "Stores cached counters in a separate table"
  s.files = Dir["{lib}/**/*"] + ["MIT-LICENSE", "Rakefile", "Gemfile", "install.rb"]
  s.version = "0.0.1"
end

