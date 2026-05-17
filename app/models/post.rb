class Post < ApplicationRecord
  validates :title, presence: true, uniqueness: true
  validates :post, presence: true
end
