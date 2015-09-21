class SignatureValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    value ||= {}
    signing_key = RbNaCl::Util.hex2bin(record.source)
    signature = RbNaCl::Util.hex2bin(value['signature'])
    ciphertext = value['ciphertext']
    begin
      RbNaCl::Signatures::Ed25519::VerifyKey.new(signing_key).verify(signature, ciphertext)
    rescue RbNaCl::BadSignatureError, RbNaCl::LengthError
      record.errors[attribute] << 'has an invalid signature'
    end
  end
end

class Message < ActiveRecord::Base
  validates :source, presence: true
  validates_format_of :source, with: /[a-f0-9]{64}/
  validates :destination, presence: true
  validates_format_of :destination, with: /[a-f0-9]{64}/
  validates :metadata, presence: true, signature: true
  validates :body, presence: true, signature: true
end
