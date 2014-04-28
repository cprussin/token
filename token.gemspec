$:.push File.expand_path('../lib', __FILE__)
require 'token/version'

Gem::Specification.new do |s|
	s.name        = 'token'
	s.version     = Token::VERSION
	s.platform    = Gem::Platform::RUBY
	s.authors     = ['Connor Prussin']
	s.email       = %w(cprussin@bci-incorporated.com)
	s.homepage    = 'http://cprussin.net/token'
	s.summary     = %q(A library that generates and verifies cryptographically secure, signed tokens.)
	s.licenses    = %w(WTFPL)

	readme        = File.open('README.md', 'r').each_line.to_a
	description   = readme.index("## Description\n") + 2
	install       = readme.index("## Install\n") - 1 - description
	s.description = readme[description, install].join.gsub("\n", ' ').chomp(' ')

	s.add_development_dependency 'rspec', '~> 2.14', '>= 2.14.1'
	s.add_development_dependency 'rake'

	s.files         = `git ls-files`.split($/)
	s.test_files    = `git ls-files -- spec/*`.split($/)
	s.require_paths = %w(lib)
end
