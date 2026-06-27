require 'rails_helper'

RSpec.describe 'Theme toggle', type: :request do
  it 'renders the theme toggle button on the homepage' do
    get root_path

    expect(response).to have_http_status(:ok)
    expect(response.body).to include('data-controller="theme"')
    expect(response.body).to include('data-action="theme#toggle"')
    expect(response.body).to include('aria-label="Toggle dark mode"')
  end

  it 'includes the no-flash theme bootstrap script in the head' do
    get root_path

    expect(response.body).to include("localStorage.getItem('theme')")
  end
end
