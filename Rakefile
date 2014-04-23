# Rake
require 'rspec/core/rake_task'
RSpec::Core::RakeTask.new(:spec) do |t|
	t.rspec_opts = %w(--color --format nested)
end

# Gem build
desc 'Build the gem'
task :build do
	`gem build token.gemspec`
end

task :default => :spec
