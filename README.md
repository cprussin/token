# Token

http://rubygems.org/gems/token

## Description

Token is a library that generates and verifies cryptographically secure, signed
expiring tokens.  The tokens contain an integer payload, which is intended to
be used as a UID field.  When verifying a token, the token is checked to ensure
that they it is not expired and that the IP address issuing the verification is
the same as the one that generated the token.

## Install

Manually:

```bash
gem install token
```

or with Bundler (add to your `Gemfile`):

```ruby
gem 'token'
```

## Usage

```ruby
require 'token'

# Set up the token generator
cipher = 'AES-256-CFB'
key    = OpenSSL::Cipher.new(cipher).random_key
iv     = OpenSSL::Cipher.new(cipher).random_iv
token  = Token.new(cipher, key, iv)

# Generate a token
uid     = 0
ip      = '0.0.0.0'
expires = Time.now + 60 * 60 * 24  # Tomorrow
tok     = token.generate(uid, ip, expires)

# Validate a token
token.validate(tok, '0.0.0.1')  # raises Token::Error
token.validate(tok, '0.0.0.0')  # => 0

# Validate a token, and return a replacement one with an extended expiration
new_expires = Time.now + 2 * 60 * 60 * 24  # In 2 days
token.validate(tok, '0.0.0.0', new_expires)  # => [0, #<Token>]
```
