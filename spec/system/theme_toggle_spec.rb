require 'rails_helper'

RSpec.describe 'Theme toggle', type: :system do
  before { driven_by(:selenium_chrome_headless) }

  it 'toggles dark mode and persists across reloads' do
    current_window.resize_to(1280, 800)
    visit root_path
    page.execute_script("localStorage.setItem('theme', 'light')")
    visit root_path
    expect(page).to have_css('html:not(.dark)')

    find("button[aria-label='Toggle dark mode']").click
    expect(page).to have_css('html.dark')
    expect(page.evaluate_script("localStorage.getItem('theme')")).to eq('dark')

    visit root_path
    expect(page).to have_css('html.dark')
  end
end
