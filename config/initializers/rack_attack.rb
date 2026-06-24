class Rack::Attack
  # Throttle magic-link requests to prevent abuse.
  throttle('sessions/ip', limit: 5, period: 15.minutes) do |req|
    req.ip if req.path == '/session' && req.post?
  end

  throttle('sessions/email', limit: 5, period: 15.minutes) do |req|
    if req.path == '/session' && req.post?
      req.params['email'].to_s.strip.downcase.presence
    end
  end
end
