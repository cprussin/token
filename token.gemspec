$:.push File.expand_path('../lib', __FILE__)
require 'token/version'

Gem::Specification.new do |s|
	s.name        = 'token'
	s.version     = Token::VERSION
	s.platform    = Gem::Platform::RUBY
	s.authors     = ['Connor Prussin']
	s.email       = %w(connor@prussin.net)
	s.homepage    = 'https://connor.prussin.net/token'
	s.summary     = %q(A library that generates and verifies cryptographically secure, signed tokens.)
	s.licenses    = %w(WTFPL)

	readme        = File.open('README.md', 'r').each_line.to_a
	description   = readme.index("## Description\n") + 2
	install       = readme.index("## Install\n") - 1 - description
	s.description = readme[description, install].join.gsub("\n", ' ').chomp(' ')

	s.add_development_dependency 'rspec', '~> 3.0', '>= 2.14.1'
	s.add_development_dependency 'rake', '~> 10.3', '>= 10.3.1'
	s.add_development_dependency 'redcarpet', '~> 3.1', '>= 3.1.1'
	s.add_development_dependency 'yard', '~> 0.8.7', '>= 0.8.7.4'

	s.files         = `git ls-files`.split($/)
	s.test_files    = `git ls-files -- spec/*`.split($/)
	s.require_paths = %w(lib)
end
