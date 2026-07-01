require 'rails_helper'

RSpec.describe 'Header responsiveness', type: :system do
  before { driven_by(:selenium_chrome_headless) }

  SOCIAL_ALTS = ['Github Profile', 'Gitlab Profile', 'LinkedIn Profile'].freeze

  def first_visible(alt, prop)
    page.evaluate_script(
      "Array.from(document.querySelectorAll(\"img[alt='#{alt}']\"))" \
      ".map(e => e.#{prop}).find(v => v > 0) || 0"
    )
  end

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

  it 'shows the social icons inline on desktop, square, w-8, aligned with the fox' do
    current_window.resize_to(1280, 800)
    visit root_path

    fox_top = first_visible('Fox', 'getBoundingClientRect().top')
    SOCIAL_ALTS.each do |alt|
      width = first_visible(alt, 'offsetWidth')
      height = first_visible(alt, 'offsetHeight')
      expect(width).to eq(32)
      expect(width).to eq(height)
      expect(first_visible(alt, 'getBoundingClientRect().top')).to eq(fox_top)
    end
  end

  it 'hides the inline social icons on mobile and shows them in the opened sidebar' do
    current_window.resize_to(375, 700)
    visit root_path

    SOCIAL_ALTS.each do |alt|
      expect(first_visible(alt, 'offsetWidth')).to eq(0)
    end

    find("button[aria-label='On this page']").click

    within("[data-sidebar-target='panel']") do
      SOCIAL_ALTS.each { |alt| expect(page).to have_css("img[alt='#{alt}']", visible: true) }
    end
    SOCIAL_ALTS.each { |alt| expect(first_visible(alt, 'offsetWidth')).to eq(24) }
  end

  it 'links the LinkedIn icon to the profile' do
    current_window.resize_to(1280, 800)
    visit root_path

    expect(page).to have_css(
      "a[href='https://www.linkedin.com/in/alexandre-silvestri'] img[alt='LinkedIn Profile']"
    )
  end
end
