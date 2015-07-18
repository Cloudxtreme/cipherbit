class Message < ActiveRecord::Base
  validates :source, presence: true
  validates_format_of :source, with: /[a-f0-9]{64}/
  validates :destination, presence: true
  validates_format_of :destination, with: /[a-f0-9]{64}/
  validates :metadata, presence: true
  validates :body, presence: true

end
