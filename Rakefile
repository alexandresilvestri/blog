require_relative 'config/application'

Rails.application.load_tasks

namespace :dev do
  desc 'Start containers'
  task :up do
    sh 'docker compose up -d'
  end

  desc 'Stop containers'
  task :down do
    sh 'docker compose down'
  end

  desc 'Stop containers and remove volumes'
  task :down_with_volumes do
    sh 'docker compose down -v'
  end

  desc 'run migrations'
  task :migrate do
    sh 'docker compose exec web bin/rails db:migrate'
  end

  desc 'run seeds'
  task :seed do
    sh 'docker compose exec web bin/rails db:seeds'
  end

  desc 'clean database (drop, recreate, migrate, seed)'
  task :clean do
    sh 'docker compose exec web bin/rails db:reset'
  end

  desc 'Run tests'
  task :test do
    sh 'bundle exec rspec'
  end

  desc 'Run rubocop'
  task :lint do
    sh 'bundle exec rubocop'
  end

  desc 'Full setup: up, migrate and seed'
  task setup: [:up, :migrate, :seed]
end
