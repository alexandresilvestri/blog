require 'rails_helper'

RSpec.describe 'Header responsiveness', type: :system do
  before { driven_by(:selenium_chrome_headless) }

  it 'hides the brand text on mobile but keeps the fox icon' do
    current_window.resize_to(375, 700)
    visit root_path

    expect(page).to have_css("img[alt='Fox']", visible: true)
    expect(page).not_to have_text('Alexandre Silvestri')
  end

  it 'shows the brand text on desktop' do
    current_window.resize_to(1280, 800)
    visit root_path

    expect(page).to have_text('Alexandre Silvestri')
  end

  it 'keeps the github and gitlab icons square at mobile width' do
    current_window.resize_to(375, 700)
    visit root_path

    %w[Github\ Profile Gitlab\ Profile].each do |alt|
      width = page.evaluate_script("document.querySelector(\"img[alt='#{alt}']\").offsetWidth")
      height = page.evaluate_script("document.querySelector(\"img[alt='#{alt}']\").offsetHeight")
      expect(width).to eq(32)
      expect(height).to eq(32)
    end
  end
end
