require 'rails_helper'

RSpec.describe 'Posts index', type: :system do
  before do
    driven_by(:selenium_chrome_headless)
    Post.create!(title: 'June post', body: 'b', created_at: Time.utc(2026, 6, 15))
    Post.create!(title: 'May post', body: 'b', created_at: Time.utc(2026, 5, 10))
  end

  it 'switches the whole page between English and Portuguese' do
    current_window.resize_to(1280, 800)
    visit root_path

    expect(page).to have_text('2026 - June')
    expect(page).to have_text(/on this page/i)

    click_link 'PT'

    expect(page).to have_text('2026 - Junho')
    expect(page).to have_text(/nesta página/i)
  end

  it 'opens the month list from the burger menu on mobile' do
    current_window.resize_to(375, 700)
    visit root_path

    expect(page).to have_link('2026 - June', visible: :hidden)

    find("button[aria-label='On this page']").click

    within("[data-sidebar-target='panel']") do
      expect(page).to have_link('2026 - June', visible: true)
      click_link '2026 - May'
    end

    expect(page).to have_link('2026 - May', visible: :hidden)
    expect(page).to have_current_path(/#2026-05\z/, url: true)
  end
end
