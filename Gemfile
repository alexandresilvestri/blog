source 'https://rubygems.org'

gem 'rails', '~> 8.1.3'
gem 'propshaft'
gem 'pg', '~> 1.6'
gem 'puma', '>= 5.0'
gem 'turbo-rails'
gem 'stimulus-rails'
gem 'jbuilder'
gem 'bcrypt', '~> 3.1.7'
gem 'aws-sdk-s3', '~> 1.225'
gem 'jsbundling-rails', '~> 1.3'
gem 'rack-attack', '~> 6.8'
gem 'tailwindcss-rails', '~> 4.4'

gem 'solid_cache'
gem 'solid_queue'
gem 'solid_cable'

gem 'bootsnap', require: false

gem 'kamal', require: false

gem 'thruster', require: false

gem 'image_processing', '~> 2.0'

group :development, :test do
  gem 'rspec-rails', '~> 8.0'
  gem 'debug', platforms: %i[ mri windows ], require: 'debug/prelude'
  gem 'bundler-audit', require: false
  gem 'brakeman', require: false
  gem 'rubocop-rails-omakase', require: false
end

group :development do
  gem 'web-console'
  gem 'pry-byebug'
  gem 'hotwire-livereload'
end

group :test do
  gem 'testcontainers-postgres'
  gem 'capybara'
  gem 'selenium-webdriver'
end
