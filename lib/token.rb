require 'openssl'

# This class provides token creation and validation.
class Token
	class Error < Exception; end
	def initialize(algorithm, key, iv)
		@algorithm = algorithm
		@key       = key
		@iv        = iv
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
		crypt = OpenSSL::Cipher.new(@algorithm)
		crypt.encrypt
		crypt.key = @key
		crypt.iv = @iv
		token = crypt.update(token) + crypt.final
	end

	# Verifies the validity of the given token and ip and returns the associated
	# uid and a replacement token, if successful.
	def validate(token, ip, extension_expires = nil)

		# Decrypt the token
		crypt = OpenSSL::Cipher.new(@algorithm)
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
end
