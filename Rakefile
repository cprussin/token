require 'yard'
require 'rspec/core/rake_task'

# Gem build
desc 'Build the gem'
task (:build) {`gem build token.gemspec`}

# Generate YARD documentation
YARD::Rake::YardocTask.new

# Test gem
RSpec::Core::RakeTask.new do |t|
	t.rspec_opts = %w(--color --format nested)
end

# By default, test, generate documentation, and build
task :default => [:spec, :yard, :build]
