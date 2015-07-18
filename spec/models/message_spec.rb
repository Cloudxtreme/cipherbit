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

  let(:source) { hex_string }
  let(:destination) { hex_string }
  let(:metadata) { hex_string(rand(50..100)) }
  let(:metadata_nonce) { hex_string(24) }
  let(:body) { hex_string(rand(50..100)) }
  let(:body_nonce) { hex_string(24) }

  let(:attributes) do
    { source: source,
      destination: destination,
      metadata: { metadata: metadata,
                  metadata_nonce: metadata_nonce},
      body: { body: body,
              body_nonce: body_nonce }
    }
  end
  let(:subject) do
    Message.new(attributes)
  end

  it 'allows valid attributes' do
    expect(subject).to be_valid
  end

  %i(source destination metadata body).each do |attribute|
    it "is invalid when #{attribute} is missing" do
      expect(Message.new(attributes.except(attribute))).to_not be_valid
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
