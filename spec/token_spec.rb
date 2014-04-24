require "#{File.dirname(__FILE__)}/../lib/token"

describe Token do
	context 'with a phony token' do
		it 'fails verification' do
			expect{Token.verify('phony')}.to raise_error
		end
	end

	shared_examples_for 'a token generator' do
		it 'passes verification' do
			expect(generator.verify(token)).to eq(payload)
		end

		context 'when expired' do
			before :each do
				new_now = Time.now + 1
				allow(Time).to receive(:now) {new_now}
			end

			it 'fails verification' do
				expect{generator.verify(token)}.to raise_error
			end
		end
	end

	context 'with class defaults' do
		it_behaves_like 'a token generator' do
			let!(:generator) {Token}
			let!(:token) {Token.generate(0, Time.now + 1)}
			let!(:payload) {0}
		end
	end

	context 'with a custom cipher' do
		let!(:tok) {Token.generate(0, Time.now + 1)}

		before :each do
			Token.cipher = 'AES-128-CFB'
		end

		after :each do
			Token.reset
		end

		it 'does not verify the old token' do
			expect{Token.verify(tok)}.to raise_error
		end

		it_behaves_like 'a token generator' do
			let!(:generator) {Token}
			let!(:token) {Token.generate(0, Time.now + 1)}
			let!(:payload) {0}
		end
	end

	context 'with a custom payload specification' do
		before :each do
			Token.payload_spec = 'LA*'
		end

		after :each do
			Token.reset
		end

		it_behaves_like 'a token generator' do
			let!(:generator) {Token}
			let!(:token) {Token.generate([1, 'test'], Time.now + 1)}
			let!(:payload) {[1, 'test']}
		end
	end

	context 'with instances of Token' do
		let(:generator1) {Token.new}
		let(:generator2) {Token.new(cipher: 'DES3')}

		context 'with default parameters' do
			it_behaves_like 'a token generator' do
				let!(:generator) {generator1}
				let!(:token) {generator.generate(0, Time.now + 1)}
				let!(:payload) {0}
			end
		end

		context 'with a custom cipher' do
			it_behaves_like 'a token generator' do
				let!(:generator) {generator2}
				let!(:token) {generator.generate(0, Time.now + 1)}
				let!(:payload) {0}
			end
		end

		context 'with a custom payload specification' do
			before :each do
				generator1.payload_spec = 'A*'
			end

			it_behaves_like 'a token generator' do
				let!(:generator) {generator1}
				let!(:token) {generator.generate('other', Time.now + 1)}
				let!(:payload) {'other'}
			end
		end
	end
end
