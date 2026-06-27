require 'rails_helper'

RSpec.describe 'Self-hosted fonts' do
  let(:assets) { Rails.application.assets }
  let(:css) { assets.compilers.compile(assets.load_path.find('tailwind.css')) }

  it 'fingerprints the bundled woff2 files' do
    %w[InterVariable InterVariable-Italic MesloLGS-Regular].each do |name|
      asset = assets.load_path.find("#{name}.woff2")
      expect(asset).not_to be_nil
      expect(asset.digested_path.to_s).to match(/\A#{Regexp.escape(name)}-\h+\.woff2\z/)
    end
  end

  it 'declares @font-face with digested src for Inter and MesloLGS' do
    expect(css).to include('@font-face')
    expect(css).to match(%r{url\(["']?/assets/InterVariable-\h+\.woff2["']?\)})
    expect(css).to match(%r{url\(["']?/assets/MesloLGS-Regular-\h+\.woff2["']?\)})
  end

  it 'maps body to Inter and code to MesloLGS' do
    expect(css).to include('--font-sans:"Inter"')
    expect(css).to include('--font-mono:"MesloLGS"')
  end
end
