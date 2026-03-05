# frozen_string_literal: true

require 'rake/testtask'
require 'rubocop/rake_task'

RuboCop::RakeTask.new(:lint)

Rake::TestTask.new(:test_unit) do |test|
  test.libs << 'test'
  test.test_files = ['test/omniauth_lastfm_test.rb']
end

Rake::TestTask.new(:test_rails_integration) do |test|
  test.libs << 'test'
  test.test_files = ['test/rails_integration_test.rb']
end

task test: [:test_unit]
task test_all: %i[test_unit test_rails_integration]
task default: %i[lint test]
