# frozen_string_literal: true

require "bundler/gem_tasks"
require "rake/testtask"

Rake::TestTask.new(:test) do |t|
  t.libs << "test"
  t.libs << "lib"
  t.test_files = FileList["test/**/*_test.rb"] - FileList["test/global_extend/*"]
end

task default: :test

Rake::TestTask.new(:test_1) do |t|
  t.libs << "test"
  t.libs << "lib"
  t.test_files = FileList["test/global_extend/activity_call_test.rb"]
end

Rake::TestTask.new(:test_2) do |t|
  t.libs << "test"
  t.libs << "lib"
  t.test_files = FileList["test/global_extend/integration_test.rb"]
end
