# frozen_string_literal: true

require "testcontainers/postgres"

module Testcontainers
  class << self
    attr_accessor :postgres
  end
end

RSpec.configure do |config|
  config.before(:suite) do
    Testcontainers.postgres = Testcontainers::PostgresContainer.new("postgres:16-alpine").start

    ActiveRecord::Base.establish_connection(Testcontainers.postgres.database_url)
    load Rails.root.join("db/schema.rb")
  end

  config.after(:suite) do
    Testcontainers.postgres&.stop
    Testcontainers.postgres&.remove
  end
end
