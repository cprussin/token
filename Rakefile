require 'yard'
require 'rspec/core/rake_task'

# Clean working directory
desc 'Remove generated files'
task (:clean) {`rm -rf .yardoc doc token-*.gem`}

# Gem build
desc 'Build the gem'
task (:build) {`gem build token.gemspec`}

# Push the gem to the rubygems server
desc 'Push the gem'
task (:push) do
	require "#{File.dirname(__FILE__)}/lib/token/version"
	`gem push token-#{Token::VERSION}`
end

# Generate YARD documentation
YARD::Rake::YardocTask.new

# Test gem
RSpec::Core::RakeTask.new do |t|
	t.rspec_opts = %w(--color --format nested)
end

# By default, test, generate documentation, and build
task :default => [:spec, :yard, :build]
