require 'rails_helper'

RSpec.describe SessionMailer, type: :mailer do
  let(:user) { User.create!(email: 'admin@example.com') }

  describe '#magic_link' do
    let(:mail) { described_class.magic_link(user) }

    it 'sends to the user with the configured from and subject' do
      expect(mail.to).to eq(['admin@example.com'])
      expect(mail.from).to eq([ENV.fetch('MAIL_FROM', 'noreply@alexandresilvestri.com.br')])
      expect(mail.subject).to eq('Your sign-in link')
    end

    it 'embeds a verify link whose token resolves to the user' do
      body = mail.body.encoded
      token = body[%r{/session/verify/([^"\s]+)}, 1]
      expect(token).to be_present
      expect(User.find_by_token_for(:magic_link, token)).to eq(user)
    end
  end
end
