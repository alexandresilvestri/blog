class TranslatePostJob < ApplicationJob
  queue_as :default

  def perform(post)
    translator = OpenRouter::Translator.new
    post.update!(
      title_en: translator.translate(post.title),
      body_en: translator.translate(post.body.to_trix_html)
    )
  end
end
