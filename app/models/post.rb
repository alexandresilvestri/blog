class Post < ApplicationRecord
  has_rich_text :body
  has_rich_text :body_en

  validates :title, presence: true, uniqueness: true
  validates :body, presence: true

  def localized_title
    I18n.locale == :en && title_en.present? ? title_en : title
  end

  def localized_body
    I18n.locale == :en && body_en.body.present? ? body_en : body
  end
end
