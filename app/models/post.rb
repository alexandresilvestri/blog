class Post < ApplicationRecord
  has_rich_text :body

  validates :title, presence: true, uniqueness: true
  validates :body, presence: true
end
