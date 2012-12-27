require "rake/testtask"
require "pry"
require_relative "app"

Rake::TestTask.new do |t|
  t.pattern = "test/*_{test,spec}.rb"
  t.verbose = true
end

task :default => [:test]

task :console do
  require_relative "models/init"
  binding.pry
end
