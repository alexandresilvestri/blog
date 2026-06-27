require 'rails_helper'

RSpec.describe 'Posts', type: :request do
  let!(:admin) { User.create!(email: 'admin@example.com') }
  let!(:post_record) { Post.create!(title: 'Hello', body: 'hi') }
  let(:valid_params) { { post: { title: 'New', body: 'body text' } } }

  describe 'index grouped by month with locale switching' do
    let!(:dated_post) do
      Post.create!(title: 'Grouped post', body: 'body',
                   created_at: Time.utc(2026, 6, 15))
    end

    it 'renders month headings, sidebar and titles in English by default' do
      get root_path
      expect(response.body).to include('2026 - June')
      expect(response.body).to include('On this page')
      expect(response.body).to include('Grouped post')
    end

    it 'localizes month headings and sidebar in Portuguese' do
      get root_path, params: { locale: 'pt' }
      expect(response.body).to include('2026 - Junho')
      expect(response.body).to include('Nesta página')
    end

    it 'falls back to the default locale for unknown values' do
      get root_path, params: { locale: 'xx' }
      expect(response.body).to include('On this page')
    end
  end

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

  describe 'inline images in body' do
    let(:blob) do
      ActiveStorage::Blob.create_and_upload!(
        io: Rails.root.join('spec/fixtures/files/sample.png').open,
        filename: 'sample.png',
        content_type: 'image/png'
      )
    end

    let(:post_with_image) do
      Post.create!(
        title: 'With image',
        body: ActionText::Content.new.append_attachables(blob)
      )
    end

    it 'persists the embedded image attachment' do
      expect(post_with_image.body.embeds.count).to eq(1)
    end

    it 'renders the image inline on show' do
      get post_path(post_with_image)
      expect(response).to have_http_status(:ok)
      expect(response.body).to include('<img')
      expect(response.body).to include('/rails/active_storage/')
      expect(response.body).to include('sample.png')
    end
  end
end
