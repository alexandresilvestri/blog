require 'rails_helper'

RSpec.describe User, type: :model do
  subject { described_class.new(email: 'admin@example.com') }

  it 'is valid with an email' do
    expect(subject).to be_valid
  end

  it 'is invalid without an email' do
    subject.email = nil
    expect(subject).not_to be_valid
    expect(subject.errors[:email]).to include("can't be blank")
  end

  it 'is invalid with a duplicate email' do
    described_class.create!(email: 'admin@example.com')
    expect(subject).not_to be_valid
    expect(subject.errors[:email]).to include('has already been taken')
  end

  it 'normalizes the email (strip + downcase)' do
    user = described_class.create!(email: '  Admin@Example.COM ')
    expect(user.email).to eq('admin@example.com')
  end

  describe 'magic_link token' do
    let(:user) { described_class.create!(email: 'admin@example.com') }

    it 'round-trips a valid token' do
      token = user.generate_token_for(:magic_link)
      expect(described_class.find_by_token_for(:magic_link, token)).to eq(user)
    end

    it 'returns nil after the token expires' do
      token = user.generate_token_for(:magic_link)
      travel 16.minutes do
        expect(described_class.find_by_token_for(:magic_link, token)).to be_nil
      end
    end

    it 'returns nil for a garbage token' do
      expect(described_class.find_by_token_for(:magic_link, 'nonsense')).to be_nil
    end
  end
end
