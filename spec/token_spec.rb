require "#{File.dirname(__FILE__)}/../lib/token"

describe Token do
	before(:all) do
		key = OpenSSL::Cipher.new('AES-256-CFB').random_key
		iv = OpenSSL::Cipher.new('AES-256-CFB').random_iv
		@token = Token.new('AES-256-CFB', key, iv)
	end

	context 'with a phony token' do
		it 'fails validation' do
			expect{@token.validate('phony', '0.0.0.0')}.to raise_error
		end
	end

	let(:tok) {@token.generate(0, '0.0.0.0', Time.now + 1)}

	it 'passes validation' do
		expect(@token.validate(tok, '0.0.0.0')).to eq(0)
	end

	it 'passes validation, returning an extended token' do
		tok
		allow(@token).to receive(:generate) {'replacement token'}
		expect(@token.validate(tok, '0.0.0.0', Time.now + 5)).to eq([0, 'replacement token'])
	end

	context 'when expired' do
		before :each do
			tok
			new_now = Time.now + 1
			allow(Time).to receive(:now) {new_now}
		end

		it 'fails validation' do
			expect{@token.validate(tok, '0.0.0.0')}.to raise_error
		end
	end

	context 'with a token for another ip' do
		it 'fails validation' do
			expect{@token.validate(tok, '0.0.0.1')}.to raise_error
		end
	end
end
