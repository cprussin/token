require "#{File.dirname(__FILE__)}/../lib/token"

describe Token do
	context 'with a phony token' do
		it 'fails verification' do
			expect{Token.verify('phony', '0.0.0.0')}.to raise_error
		end
	end

	let!(:tok) {Token.generate(0, '0.0.0.0', Time.now + 1)}

	shared_examples_for 'a token generator' do
		it 'passes verification' do
			expect(generator.verify(token, '0.0.0.0')).to eq(0)
		end

		it 'passes verification, returning an extended token' do
			val = generator.verify(token, '0.0.0.0', Time.now + 5)
			expect(val[0]).to be(0)
			expect(val[1].class).to be(String)
			expect(val.length).to be(2)
		end

		context 'when expired' do
			before :each do
				new_now = Time.now + 1
				allow(Time).to receive(:now) {new_now}
			end

			it 'fails verification' do
				expect{generator.verify(token, '0.0.0.0')}.to raise_error
			end
		end

		context 'with a token for another ip' do
			it 'fails verification' do
				expect{generator.verify(token, '0.0.0.1')}.to raise_error
			end
		end
	end

	context 'with class defaults' do
		it_behaves_like 'a token generator' do
			let!(:generator) {Token}
			let!(:token) {tok}
		end
	end

	context 'with a custom cipher' do
		before :each do
			Token.cipher = 'AES-128-CFB'
		end

		after :each do
			Token.reset
		end

		it 'does not verify the old token' do
			expect{Token.verify(tok, '0.0.0.0')}.to raise_error
		end

		it_behaves_like 'a token generator' do
			let!(:generator) {Token}
			let!(:token) {Token.generate(0, '0.0.0.0', Time.now + 1)}
		end
	end

	context 'with instances of Token' do
		it_behaves_like 'a token generator' do
			let!(:generator) {Token.new}
			let!(:token) {generator.generate(0, '0.0.0.0', Time.now + 1)}
		end
	end
end
