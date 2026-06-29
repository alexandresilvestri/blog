require 'net/http'
require 'json'

module OpenRouter
  class Translator
    class Error < StandardError; end

    ENDPOINT = URI('https://openrouter.ai/api/v1/chat/completions')
    DEFAULT_MODEL = 'anthropic/claude-sonnet-4'
    SYSTEM_PROMPT = <<~PROMPT.freeze
      You are a professional translator. Translate the user's content from Portuguese to English.
      Preserve all HTML tags, attributes, URLs, and <action-text-attachment> tags and their sgid
      values exactly as they appear. Do not add, remove, or reorder any markup. Return only the
      translated content, with no explanations, comments, or code fences.
    PROMPT

    def initialize(api_key: ENV['OPENROUTER_API_KEY'], model: ENV.fetch('OPENROUTER_MODEL', DEFAULT_MODEL))
      @api_key = api_key
      @model = model
    end

    def translate(content)
      response = post(content)

      unless response.is_a?(Net::HTTPSuccess)
        raise Error, "OpenRouter request failed: #{response.code} #{response.body}"
      end

      JSON.parse(response.body).dig('choices', 0, 'message', 'content')
    end

    private

    def post(content)
      http = Net::HTTP.new(ENDPOINT.host, ENDPOINT.port)
      http.use_ssl = true
      http.open_timeout = 10
      http.read_timeout = 120

      request = Net::HTTP::Post.new(ENDPOINT)
      request['Authorization'] = "Bearer #{@api_key}"
      request['Content-Type'] = 'application/json'
      request.body = {
        model: @model,
        messages: [
          { role: 'system', content: SYSTEM_PROMPT },
          { role: 'user', content: content }
        ]
      }.to_json

      http.request(request)
    end
  end
end
