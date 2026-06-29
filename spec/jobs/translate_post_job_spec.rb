require 'rails_helper'

RSpec.describe TranslatePostJob do
  let(:post_record) { Post.create!(title: 'Olá', body: 'corpo') }

  it 'stores the translated title and body on the post' do
    translator = instance_double(OpenRouter::Translator)
    allow(OpenRouter::Translator).to receive(:new).and_return(translator)
    allow(translator).to receive(:translate).and_return('Hello', '<div>body</div>')

    described_class.perform_now(post_record)

    expect(post_record.reload.title_en).to eq('Hello')
    expect(post_record.body_en.to_plain_text).to eq('body')
  end
end
