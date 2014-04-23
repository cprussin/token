require 'openssl'

# This class provides token creation and validation.
class Token
	class Error < Exception; end

	attr_accessor :cipher, :key, :iv

	# Create a new token generator.
	def initialize(cipher = nil, options = {})
		if cipher.nil?
			self.class.reset if self.class.cipher.nil?
			@cipher = self.class.cipher
			@key    = self.class.key
			@iv     = self.class.iv
		else
			@cipher = cipher
			cipher  = OpenSSL::Cipher.new(cipher)
			@key    = options[:key] || cipher.random_key
			@iv     = options[:iv]  || cipher.random_iv
		end
	end

	# Creates a token consisting of the given uid, ip address, persistency flag,
	# and expiration date.
	def generate(uid, ip, expires)
		token = [
			uid,
			ip.split('.').map(&:to_i),
			expires.to_i
		]
		token = token.flatten.pack('LCCCCL')

		# Append the token's hash
		token += Digest::SHA256.hexdigest(token)

		# Encrypt the token
		crypt = OpenSSL::Cipher.new(@cipher)
		crypt.encrypt
		crypt.key = @key
		crypt.iv = @iv
		token = crypt.update(token) + crypt.final
	end

	# Verifies the validity of the given token and ip and returns the associated
	# uid and a replacement token, if successful.
	def verify(token, ip, extension_expires = nil)

		# Decrypt the token
		crypt = OpenSSL::Cipher.new(@cipher)
		crypt.decrypt
		crypt.key = @key
		crypt.iv = @iv
		tok = crypt.update(token) + crypt.final

		# Split the token
		tok = tok.unpack('LCCCCLA*')

		# Validate the token
		time_valid = Time.at(tok[5]) > Time.now
		ip_valid = ip == tok[1..4].join('.')
		hash = Digest::SHA256.hexdigest(tok[0..5].pack('LCCCCL'))
		hash_valid = hash == tok[6]
		unless time_valid && ip_valid && hash_valid
			raise Error, 'Session is invalid'
		end

		# Return the uid and the replacement token
		if !extension_expires.nil?
			[tok[0], generate(tok[0], ip, extension_expires)]
		else
			tok[0]
		end
	end

	class << self
		attr_reader :cipher, :key, :iv

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

		# Allow generate to be called on the class
		def generate(*args)
			instance.generate(*args)
		end

		# Allow verify to be called on the class
		def verify(*args)
			instance.verify(*args)
		end

		# Reset class parameters to defaults
		def reset
			@cipher = 'AES-256-CFB'
			cipher  = OpenSSL::Cipher.new(@cipher)
			@key    = cipher.random_key
			@iv     = cipher.random_iv
		end

		private

		# Retrieve the default instance
		def instance
			reset unless defined? @cipher
			@instance ||= new
		end
	end
end
