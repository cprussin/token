# Token

[![Gem Version](https://badge.fury.io/rb/token.svg)](http://rubygems.org/gems/token)

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
generated key and initialization vector.  These defaults can be overridden as
follows:

```ruby
require 'token'

Token.cipher       = 'AES-256-CFB'
Token.key          = OpenSSL::Cipher.new(Token.cipher).random_key
Token.iv           = OpenSSL::Cipher.new(Token.cipher).random_iv
Token.payload_spec = 'L'
```

You can reset the class to its default cipher with a new random key and
initialization vector by using `Token.reset`.

### Generate a Token

When tokens are generated, three parameters must by specified:

 * A payload.  By default, this is a single integer value.
 * The IP address to assign to this token.
 * The `Time` after which verification of this token should fail.

An example of generating a token is:

```ruby
in_one_day = Time.now + 60 * 60 * 24
token = Token.generate(0, '0.0.0.0', in_one_day)
```

### Verify a token

When verifying a token, the token is checked to ensure that it is not expired
and that the IP address issuing the verification is the same as the
one that generated the token.

```ruby
token = Token.generate(0, '0.0.0.0', Time.now + 2)

Token.verify(token, '0.0.0.1')  # raises Token::Error
Token.verify(token, '0.0.0.0')  # => 0
sleep 2
Token.verify(token, '0.0.0.0')  # raises Token::Error
```

If given an extended expiration date when verifying a token, the library will
generate a replacement token with that expiration date.  This can be used to
expire tokens after a timeout after the user is finished using the service
issuing the tokens.

```ruby
token = Token.generate(0, '0.0.0.0', Time.now + 5)

Token.verify(token, '0.0.0.0', Time.now + 5)  # => [0, "..."]
```

### Modify the Payload Format

By default, the payload of the token is a single integer value.  This is useful
when you are handling login, as it can specify the ID of the user with the
token.  However, sometimes applications require tokens with more intricate
payloads.

To change the format of the payload to contain multiple values or different
formats, modify the `payload_spec` parameter.  This parameter should be in the
same format as expected by `Array.pack`.  The default value is `'L'`.

```ruby
Token.payload_spec = 'LA*'
token = Token.generate([0, 'foo'], '0.0.0.0', Time.now + 5)
Token.verify(token, '0.0.0.0')                # => [0, 'foo']
Token.verify(token, '0.0.0.0', Time.now + 5)  # => [[0, 'foo'], "..."]
```

Note that if the `payload_spec` only contains a single field, then the payload
argument to `Token.generate` can be a scalar. Otherwise, the argument must be
an array.

### Instances of the Token Class

You can create instances of the `Token` class and use the instances to generate
and verify tokens.  This is useful if you use tokens for multiple purposes in
your application and each purpose uses different cryptographic parameters or
payload formats.

```ruby
key = OpenSSL::Cipher.new('AES-128-CFB').random_key
iv  = OpenSSL::Cipher.new('AES-128-CFB').random_iv
tok = Token.new('AES-128-CFB', key: key, iv: iv)

token = tok.generate(0, '0.0.0.0', Time.now + 5)
tok.verify(token, '0.0.0.0')  # => 0
```

If you call `Token.new` without any arguments then it will create a Token class
with the default cipher, a random key, and a random initialization vector.
