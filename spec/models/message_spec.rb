require 'rails_helper'

RSpec.describe Message, type: :model do

  def random_non_hex_letter
    (103..122).to_a.sample.chr
  end

  def hex_string(length = 64)
    (0...length).map{|_| '0123456789abcdef'[rand(16)]}.join('')
  end

  def bad_hex(length = 64)
    hex_string(length).tap do |hex|
      hex[rand(length)] = random_non_hex_letter
    end
  end

  let(:source) {  '8513b88119e068cf464381ff0a26aac6436eb52b0b04e91621d63a0bb80018e6' }
  let(:destination) { '8513b88119e068cf464381ff0a26aac6436eb52b0b04e91621d63a0bb80018e6' }
  let(:metadata)  { 'f0ed9e49bb4e3585130a8b3c464ef97497a2be0e31553b40c095574cdfbd40b2e797692778db08c8f075d7e284122f5007d2245b1b167c722532914b38006d5a07bfeabfac4979ab76029acb9fe1ef81887618d3' }
  let(:metadata_nonce) { '9fbdc14c9bc04edb58a4b2a34d976915ddf47c7e25e4933d' }
  let(:metadata_signature) { 'd6442abf576207760854edd521ce8d4bdc8724cd6645977ddb20e018315b6d9452c7f4d50b3ad433ff52748402664ad543efb0d1035e87c9a82ef522c32ce50d' }
  let(:body) { '59c6b4dee5f6da5690ab1613969cfcb7f74619a0c8badd76b1f7d4944cea55575f512b43341d08' }
  let(:body_nonce) { 'dc061c6d41a3bb352677aea6de83823a13a2dbfd68d77323' }
  let(:body_signature) { '8437fc048ad4648fea6833d50752929ff08188640cab3b0702b75fd74f78dac7f82904634cdd741e966f620eb07cca5162cbda90964ecbf61cae6fe5c8aed50f' }

  let(:attributes) do
    { source: source,
      destination: destination,
      metadata: { ciphertext: metadata,
                  nonce: metadata_nonce,
                  signature: metadata_signature },
      body: { ciphertext: body,
              nonce: body_nonce,
              signature: body_signature }
    }
  end

  let(:subject) do
    Message.new(attributes)
  end

  it 'accepts valid parameters' do
    expect(subject).to be_valid
  end

  %i(source destination metadata body).each do |attribute|
    it "is invalid when #{attribute} is missing" do
      message = Message.new(attributes.except(attribute))
      message.valid?
      expect(message.errors).to have_key(attribute)
    end
  end

  %i(source destination).each do |attribute|
    it "is invalid when #{attribute} is not the correct length" do
      expect(Message.new(attributes.merge(attribute => hex_string(10)))).to_not be_valid
    end

    it "is invalid when #{attribute} is not a hexidecimal value" do
      expect(Message.new(attributes.merge(attribute => bad_hex))).to_not be_valid
    end
  end

end
