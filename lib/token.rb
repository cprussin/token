require 'openssl'

# This class provides token creation and validation.
class Token
	class Error < Exception; end

	attr_accessor :cipher, :key, :iv, :payload_spec

	# Create a new token generator.
	def initialize(cipher = nil, options = {})
		if cipher.nil?
			@cipher       = self.class.cipher
			@key          = self.class.key
			@iv           = self.class.iv
			@payload_spec = options[:payload_spec] || self.class.payload_spec
		else
			@cipher       = cipher
			cipher        = OpenSSL::Cipher.new(cipher)
			@key          = options[:key]          || cipher.random_key
			@iv           = options[:iv]           || cipher.random_iv
			@payload_spec = options[:payload_spec] || self.class.payload_spec
		end
	end

	# Creates a token consisting of the given payload, ip address, and expiration
	# date.
	def generate(payload, ip, expires)
		token = [
			ip.split('.').map(&:to_i),
			expires.to_i,
			payload
		]
		token = token.flatten.pack("CCCCL#{@payload_spec}")

		# Prepend the token's hash
		token.prepend(Digest::SHA256.hexdigest(token))

		# Encrypt the token
		crypt = OpenSSL::Cipher.new(@cipher)
		crypt.encrypt
		crypt.key = @key
		crypt.iv = @iv
		token = crypt.update(token) + crypt.final
	end

	# Verifies the validity of the given token and ip and returns the associated
	# payload and a replacement token, if successful.
	def verify(token, ip, extension_expires = nil)

		# Decrypt the token
		crypt = OpenSSL::Cipher.new(@cipher)
		crypt.decrypt
		crypt.key = @key
		crypt.iv = @iv
		tok = crypt.update(token) + crypt.final

		# Split the token
		tok = tok.unpack("A64CCCCL#{@payload_spec}")

		# Validate the token
		time_valid = Time.at(tok[5]) > Time.now
		ip_valid = ip == tok[1..4].join('.')
		hash = Digest::SHA256.hexdigest(tok[1..-1].pack("CCCCL#{@payload_spec}"))
		hash_valid = hash == tok[0]
		unless time_valid && ip_valid && hash_valid
			raise Error, 'Session is invalid'
		end

		# Return the payload and the replacement token
		payload = tok.length == 7 ? tok.last : tok[6..-1]
		if !extension_expires.nil?
			[payload, generate(payload, ip, extension_expires)]
		else
			payload
		end
	end

	class << self
		attr_reader :cipher, :key, :iv, :payload_spec

		# Set the default cipher
		def cipher=(cipher)
			@cipher   = cipher
			@key      = OpenSSL::Cipher.new(@cipher).random_key
			@iv       = OpenSSL::Cipher.new(@cipher).random_iv
			@instance = nil
		end

		# Set the default key
		def key=(key)
			@key      = key
			@instance = nil
		end

		# Set the default initialization vector
		def iv=(iv)
			@iv       = iv
			@instance = nil
		end

		# Set the token specification
		def payload_spec=(spec)
			@payload_spec = spec
			@instance     = nil
		end

		# Allow generate to be called on the class
		def generate(payload, ip, expires)
			instance.generate(payload, ip, expires)
		end

		# Allow verify to be called on the class
		def verify(token, ip, extension_expires = nil)
			instance.verify(token, ip, extension_expires)
		end

		# Reset class parameters to defaults
		def reset
			@cipher       = 'AES-256-CFB'
			cipher        = OpenSSL::Cipher.new(@cipher)
			@key          = cipher.random_key
			@iv           = cipher.random_iv
			@payload_spec = 'L'
		end

		private

		# Retrieve the default instance
		def instance
			@instance ||= new
		end
	end
	self.reset
end
