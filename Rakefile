# frozen_string_literal: true

require "bundler/gem_tasks"

begin
  require "rspec/core/rake_task"
  RSpec::Core::RakeTask.new(:spec)
rescue LoadError
  # RSpec is in development group, may not be available when BUNDLE_WITHOUT: development
end

begin
  require "rubocop/rake_task"
  RuboCop::RakeTask.new do |task|
    task.options = ["--config", ".rubocop.yml"]
  end
rescue LoadError
  # RuboCop is in development group, may not be available when BUNDLE_WITHOUT: development
end

default_tasks = []
default_tasks << :spec if Rake::Task.task_defined?(:spec)
default_tasks << :rubocop if Rake::Task.task_defined?(:rubocop)
task default: default_tasks unless default_tasks.empty?
