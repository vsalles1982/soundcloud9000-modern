require 'bundler/gem_tasks'
require 'rake/testtask'

Rake::TestTask.new do |task|
  task.libs << 'lib'
  task.pattern = 'spec/**/*_spec.rb'
  task.verbose = true
end

task default: :test
