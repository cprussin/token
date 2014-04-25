require 'openssl'

# This class provides token creation and validation.  It can be used as a
# singleton or by creating instances.
class Token
	attr_accessor :cipher, :key, :iv, :format

	# All token errors raise an exception of this class.
	class Error < Exception; end

	# Creates a new token generator.
	#
	# @param options [Hash] options to modify the default behavior of the token
	#   generator
	# @option options [String] :cipher The cipher to use with OpenSSL.  Defaults
	#   to 'AES-256-CFB'
	# @option options [String] :key The key to use with OpenSSL.  Defaults to a
	#   random key.  Do not specify without also specifying cipher
	# @option options [String] :iv The initialization vector to use with OpenSSL.
	#   Defaults to a random vector.  Do not specify without also specifying
	#   cipher
	# @option options [String] :format The string describing the format of the
	#   payloads.  Should be in the format expected by Array.pack.  Defaults to
	#   'L'
	def initialize(options = {})

		# Check to see if there are custom cryptographic settings
		if options.has_key? :cipher
			@cipher = options[:cipher]
			cipher  = OpenSSL::Cipher.new(@cipher)
			@key    = options[:key] || cipher.random_key
			@iv     = options[:iv]  || cipher.random_iv

		# Otherwise, set the default cryptographic settings
		else
			@cipher = self.class.cipher
			@key    = self.class.key
			@iv     = self.class.iv
		end

		# Set the payload format
		@format = options[:format] || self.class.format
	end

	# Creates a token consisting of the given payload and expiration date.
	#
	# @param payload [Array] the payload to embed in the token -- this may be a
	#   scalar if the payload format only specifies a single field
	# @param expires [Time] the time after which the token should be considered
	#   expired
	# @return [String] the generated token
	def generate(payload, expires)

		# Pack the token
		token = [
			expires.to_i,
			payload
		]
		token = token.flatten.pack("L#{@format}")

		# Prepend the token's hash
		token.prepend(Digest::SHA256.hexdigest(token))

		# Encrypt the token
		crypt = OpenSSL::Cipher.new(@cipher)
		crypt.encrypt
		crypt.key = @key
		crypt.iv = @iv
		token = crypt.update(token) + crypt.final
	end

	# Verifies the validity of the given token and, if successful, returns the
	# associated payload.
	#
	# @param token [String] the token to verify
	# @return [Array] the payload -- this will be a scalar depending on the
	#   setting for format
	# @raise [Token::Error] if the token fails to decrypt, is not signed
	#   properly, or is expired
	def verify(token)

		# Decrypt the token
		begin
			crypt = OpenSSL::Cipher.new(@cipher)
			crypt.decrypt
			crypt.key = @key
			crypt.iv = @iv
			tok = crypt.update(token) + crypt.final
		rescue
			raise Error, 'Session is invalid'
		end

		# Split the token
		tok = tok.unpack("A64L#{@format}")

		# Validate the token
		time_valid = Time.at(tok[1]) > Time.now
		hash       = Digest::SHA256.hexdigest(tok[1..-1].pack("L#{@format}"))
		hash_valid = hash == tok[0]
		raise Error, 'Session is invalid' unless time_valid && hash_valid

		# Return the payload
		tok.length == 3 ? tok.last : tok[2..-1]
	end

	class << self
		attr_reader :cipher, :format

		# Sets the class default cipher.  Note that the key and initialization
		# vector will be cleared, and if not manually reset, will be regenerated
		# randomly when necessary.
		#
		# @param cipher [String] the cipher to use with OpenSSL
		def cipher=(cipher)
			@cipher = cipher
			@key = @iv = @instance = nil
		end

		# Gets the class default encryption key, generating a new one if necessary.
		#
		# @return [String] the class default encryption key
		def key
			@key ||= OpenSSL::Cipher.new(@cipher).random_key
		end

		# Set the class default encryption key.
		#
		# @param key [String] the key to use with OpenSSL
		def key=(key)
			@key      = key
			@instance = nil
		end

		# Gets the class default encryption initialization vector, generating a new
		# one if necessary.
		#
		# @return [String] the class default initialization vector
		def iv
			@iv ||= OpenSSL::Cipher.new(@cipher).random_iv
		end

		# Set the class default initialization vector.
		#
		# @param iv [String] the initialization vector to use with OpenSSL
		def iv=(iv)
			@iv       = iv
			@instance = nil
		end

		# Set the class default token payload format.
		#
		# @param format [String] the string describing the format of the payloads.
		#   Should be in the format expected by Array.pack
		def format=(format)
			@format   = format
			@instance = nil
		end

		# Generates a token using the class default cryptographic settings and
		# payload format.
		#
		# @see Token#generate
		def generate(payload, expires)
			instance.generate(payload, expires)
		end

		# Verifies the validity of a token using the class default cryptographic
		# settings and payload format.
		#
		# @see Token#verify
		def verify(token)
			instance.verify(token)
		end

		# Resets the cipher to 'AES-256-CFB', the payload format to 'L', and the
		# key and initialization vectors to random values.
		def reset
			@cipher = 'AES-256-CFB'
			cipher  = OpenSSL::Cipher.new(@cipher)
			@key    = cipher.random_key
			@iv     = cipher.random_iv
			@format = 'L'
		end

		private

		# Retrieve the default instance.
		def instance
			@instance ||= new
		end
	end

	# Set the default settings when loading the class
	self.reset
end
