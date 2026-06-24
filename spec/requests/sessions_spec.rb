require 'rails_helper'

RSpec.describe 'Sessions', type: :request do
  let!(:admin) { User.create!(email: 'admin@example.com') }

  describe 'GET /session/new' do
    it 'renders the sign-in form' do
      get admin_path
      expect(response).to have_http_status(:ok)
    end
  end

  describe 'POST /session' do
    it 'sends one magic-link email for a known address and shows a generic flash' do
      expect do
        post session_path, params: { email: 'admin@example.com' }
      end.to have_enqueued_mail(SessionMailer, :magic_link).once
      expect(response).to redirect_to(admin_path)
      follow_redirect!
      expect(response.body).to include('Check your email')
    end

    it 'sends no email for an unknown address but shows the same generic flash' do
      expect do
        post session_path, params: { email: 'nobody@example.com' }
      end.not_to have_enqueued_mail(SessionMailer, :magic_link)
      follow_redirect!
      expect(response.body).to include('Check your email')
    end
  end

  describe 'GET verify' do
    it 'signs the user in with a valid token' do
      get verify_session_path(token: admin.generate_token_for(:magic_link))
      expect(response).to redirect_to(root_path)

      get new_post_path
      expect(response).to have_http_status(:ok)
    end

    it 'rejects an invalid/expired token' do
      get verify_session_path(token: 'garbage')
      expect(response).to redirect_to(admin_path)

      get new_post_path
      expect(response).to redirect_to(admin_path)
    end
  end

  describe 'DELETE /session' do
    it 'signs the user out' do
      sign_in(admin)
      get new_post_path
      expect(response).to have_http_status(:ok)

      delete session_path
      get new_post_path
      expect(response).to redirect_to(admin_path)
    end
  end
end
