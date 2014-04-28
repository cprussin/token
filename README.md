# [Token](http://cprussin.net/token)

[![Gem Version](https://badge.fury.io/rb/token.svg)](http://rubygems.org/gems/token) [![Dependency Status](https://gemnasium.com/cprussin/token.svg)](https://gemnasium.com/cprussin/token)

## Description

Token is a library that generates and verifies cryptographically secure, signed
string tokens.

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

### Setup

The Token class defaults to using the `AES-246-CFB` cipher with a randomly
generated key and initialization vector, and the payload format as a single
integer value.  These defaults can be overridden as follows:

```ruby
require 'token'

Token.cipher = 'AES-256-CFB'
Token.key    = OpenSSL::Cipher.new(Token.cipher).random_key
Token.iv     = OpenSSL::Cipher.new(Token.cipher).random_iv
Token.format = 'L'
```

You can reset the class to its default payload format and default cipher with
a new random key and initialization vector by using `Token.reset`.

### Generate a Token

When tokens are generated, two parameters must by specified:

 * A payload.  By default, this is a single integer value.
 * The `Time` after which verification of this token should fail.

An example of generating a token is:

```ruby
in_one_day = Time.now + 60 * 60 * 24
token      = Token.generate(0, in_one_day)
```

### Verify a token

When verifying a token, the token is checked to ensure that it is not expired.

```ruby
token = Token.generate(0, Time.now + 2)

Token.verify(token)  # => 0
sleep 2
Token.verify(token)  # raises Token::Error
```

### Modify the Payload Format

By default, the payload of the token is a single integer value.  This is useful
when you are handling login, as it can specify the ID of the user with the
token.  However, sometimes applications require tokens with more intricate
payloads.

To change the format of the payload to contain multiple values or different
formats, modify the `format` parameter.  This parameter should be in the same
format as expected by `Array.pack`.  The default value is `'L'`.

```ruby
Token.format = 'LCCCCA*'
ip_address   = '0.0.0.0'.split('.').map(&:to_i)
token        = Token.generate([15, ip_address, 'foo'], Time.now + 5)
Token.verify(token)  # => [15, 0, 0, 0, 0, 'foo']
```

Note that if the `format` only contains a single field, then the payload
argument to `Token.generate` can be a scalar. Otherwise, the argument must be
an array.  The array will be automatically flattened when generating the token,
and `verify` will always return a flat array or scalar.

### Instances of the Token Class

You can create instances of the `Token` class and use the instances to generate
and verify tokens.  This is useful if you use tokens for multiple purposes in
your application and each purpose uses different cryptographic parameters or
payload formats.

```ruby
key   = OpenSSL::Cipher.new('AES-128-CFB').random_key
iv    = OpenSSL::Cipher.new('AES-128-CFB').random_iv
tok   = Token.new('AES-128-CFB', key: key, iv: iv)
token = tok.generate(0, Time.now + 5)
tok.verify(token)  # => 0
```

If you call `Token.new` without any arguments then it will create a Token class
with the default cipher, a random key, and a random initialization vector.
