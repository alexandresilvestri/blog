# frozen_string_literal: true

module AuthHelpers
  def sign_in(user)
    get verify_session_path(token: user.generate_token_for(:magic_link))
  end
end

RSpec.configure do |config|
  config.include AuthHelpers, type: :request
  config.include ActiveSupport::Testing::TimeHelpers
end
