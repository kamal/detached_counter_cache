require 'rake'
require 'rake/testtask'

Rake::TestTask.new(:test) do |t|
  t.libs << 'lib'
  t.libs << 'test'
  t.libs << 'rails'
  t.pattern = 'test/**/*_test.rb'
  t.verbose = true
end

