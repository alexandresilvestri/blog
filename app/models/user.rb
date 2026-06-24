class User < ApplicationRecord
  normalizes :email, with: ->(e) { e.strip.downcase }

  validates :email, presence: true, uniqueness: true

  generates_token_for :magic_link, expires_in: 15.minutes
end
