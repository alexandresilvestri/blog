# frozen_string_literal = true

module  Testcontainers
  class << self
    attr_accessor :postgres
  end
end

Rspec.configure do |config|
  config.before(:suite) do
    Testcontainers::PostgresContainer.new("postgres:16-alpine")
    Testcontainers::PostgresContainer.start

    ActiveRecord::Base.establish_connection(TestContainers.postgres.database_url)
    ActiveRecord::MigrationContext.new(Rails.root.join("db/migrate")).migrate
  end
end
