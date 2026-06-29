require 'rails_helper'
require 'webmock'

RSpec.describe OpenRouter::Translator do
  include WebMock::API

  before { WebMock.enable! }
  after { WebMock.reset!; WebMock.disable! }

  subject(:translator) { described_class.new(api_key: 'test-key', model: 'test-model') }

  let(:endpoint) { 'https://openrouter.ai/api/v1/chat/completions' }

  it 'sends the content and returns the translated text' do
    stub_request(:post, endpoint)
      .with(headers: { 'Authorization' => 'Bearer test-key', 'Content-Type' => 'application/json' })
      .to_return(
        status: 200,
        body: { choices: [{ message: { content: 'Hello world' } }] }.to_json,
        headers: { 'Content-Type' => 'application/json' }
      )

    result = translator.translate('Olá mundo')

    expect(result).to eq('Hello world')
    assert_requested(:post, endpoint) do |req|
      body = JSON.parse(req.body)
      body['model'] == 'test-model' && body['messages'].last['content'] == 'Olá mundo'
    end
  end

  it 'raises when the API responds with an error' do
    stub_request(:post, endpoint).to_return(status: 500, body: 'boom')

    expect { translator.translate('x') }.to raise_error(described_class::Error, /500/)
  end
end
