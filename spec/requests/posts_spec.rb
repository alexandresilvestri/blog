require 'rails_helper'

RSpec.describe 'Posts', type: :request do
  let!(:admin) { User.create!(email: 'admin@example.com') }
  let!(:post_record) { Post.create!(title: 'Hello', post: { 'body' => 'hi' }) }
  let(:valid_params) { { post: { title: 'New', post: 'body text' } } }

  describe 'public access (logged out)' do
    it 'allows index' do
      get posts_path
      expect(response).to have_http_status(:ok)
    end

    it 'allows show' do
      get post_path(post_record)
      expect(response).to have_http_status(:ok)
    end
  end

  describe 'gated actions (logged out)' do
    it 'redirects new to sign-in' do
      get new_post_path
      expect(response).to redirect_to(admin_path)
    end

    it 'redirects edit to sign-in' do
      get edit_post_path(post_record)
      expect(response).to redirect_to(admin_path)
    end

    it 'blocks create without changing the count' do
      expect do
        post posts_path, params: valid_params
      end.not_to change(Post, :count)
      expect(response).to redirect_to(admin_path)
    end

    it 'blocks update' do
      patch post_path(post_record), params: { post: { title: 'Changed' } }
      expect(response).to redirect_to(admin_path)
      expect(post_record.reload.title).to eq('Hello')
    end

    it 'blocks destroy without changing the count' do
      expect do
        delete post_path(post_record)
      end.not_to change(Post, :count)
      expect(response).to redirect_to(admin_path)
    end
  end

  describe 'signed in' do
    before { sign_in(admin) }

    it 'creates a post' do
      expect do
        post posts_path, params: valid_params
      end.to change(Post, :count).by(1)
    end

    it 'updates a post' do
      patch post_path(post_record), params: { post: { title: 'Changed' } }
      expect(post_record.reload.title).to eq('Changed')
    end

    it 'destroys a post' do
      expect do
        delete post_path(post_record)
      end.to change(Post, :count).by(-1)
    end
  end
end
