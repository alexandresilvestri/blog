require 'rails_helper'

RSpec.describe Post, type: :model do
  subject { described_class.new(title: 'My Post', body: 'hello') }

  it 'is valid with title and body' do
    expect(subject).to be_valid
  end

  it 'is invalid without a title' do
    subject.title = nil
    expect(subject).not_to be_valid
    expect(subject.errors[:title]).to include("can't be blank")
  end

  it 'is invalid without a body' do
    subject.body = nil
    expect(subject).not_to be_valid
    expect(subject.errors[:body]).to include("can't be blank")
  end

  it 'is invalid with a duplicate title' do
    described_class.create!(title: 'My Post', body: 'hello')
    expect(subject).not_to be_valid
    expect(subject.errors[:title]).to include('has already been taken')
  end

  describe '#localized_title' do
    let(:post) { described_class.create!(title: 'Olá', body: 'corpo', title_en: 'Hello') }

    it 'returns the English title in the en locale when present' do
      I18n.with_locale(:en) { expect(post.localized_title).to eq('Hello') }
    end

    it 'falls back to the original title when no translation exists' do
      post.update!(title_en: nil)
      I18n.with_locale(:en) { expect(post.localized_title).to eq('Olá') }
    end

    it 'returns the original title in the pt locale' do
      I18n.with_locale(:pt) { expect(post.localized_title).to eq('Olá') }
    end
  end

  describe '#localized_body' do
    let(:post) { described_class.create!(title: 'Olá', body: 'corpo', body_en: 'body') }

    it 'returns the English body in the en locale when present' do
      I18n.with_locale(:en) { expect(post.localized_body.to_plain_text).to eq('body') }
    end

    it 'falls back to the original body when no translation exists' do
      post.update!(body_en: nil)
      I18n.with_locale(:en) { expect(post.localized_body.to_plain_text).to eq('corpo') }
    end

    it 'returns the original body in the pt locale' do
      I18n.with_locale(:pt) { expect(post.localized_body.to_plain_text).to eq('corpo') }
    end
  end
end
