require 'rails_helper'

RSpec.describe Post, type: :model do
  subject { described_class.new(title: 'My Post', post: { 'body' => 'hello' }) }

  it 'is valid with title and post' do
    expect(subject).to be_valid
  end

  it 'is invalid without a title' do
    subject.title = nil
    expect(subject).not_to be_valid
    expect(subject.errors[:title]).to include("can't be blank")
  end

  it 'is invalid without a post' do
    subject.post = nil
    expect(subject).not_to be_valid
    expect(subject.errors[:post]).to include("can't be blank")
  end

  it 'is invalid with a duplicate title' do
    described_class.create!(title: 'My Post', post: { 'body' => 'hello' })
    expect(subject).not_to be_valid
    expect(subject.errors[:title]).to include('has already been taken')
  end
end
