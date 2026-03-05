# frozen_string_literal: true

require_relative 'test_helper'

require 'action_controller/railtie'
require 'digest/md5'
require 'json'
require 'logger'
require 'rack/test'
require 'rails'
require 'uri'
require 'webmock/minitest'

class RailsIntegrationSessionsController < ActionController::Base
  def create
    auth = request.env.fetch('omniauth.auth')
    render json: {
      uid: auth['uid'],
      nickname: auth.dig('info', 'nickname'),
      name: auth.dig('info', 'name')
    }
  end

  def failure
    render json: { error: params[:message] }, status: :unauthorized
  end
end

class RailsIntegrationApp < Rails::Application
  config.root = File.expand_path('..', __dir__)
  config.eager_load = false
  config.secret_key_base = 'lastfm-rails-integration-test-secret-key'
  config.hosts.clear
  config.hosts << 'example.org'
  config.logger = Logger.new(nil)
  config.active_support.cache_format_version = 7.1 if config.active_support.respond_to?(:cache_format_version=)
  if config.active_support.respond_to?(:to_time_preserves_timezone=) && Gem::Version.new(Rails.version) < Gem::Version.new('8.1')
    config.active_support.to_time_preserves_timezone = :zone
  end

  config.middleware.use OmniAuth::Builder do
    provider :lastfm, 'client-key', 'client-secret'
  end

  routes.append do
    match '/auth/:provider/callback', to: 'rails_integration_sessions#create', via: %i[get post]
    get '/auth/failure', to: 'rails_integration_sessions#failure'
  end
end

RailsIntegrationApp.initialize! unless RailsIntegrationApp.initialized?

class RailsIntegrationTest < Minitest::Test
  include Rack::Test::Methods

  def setup
    super
    @previous_test_mode = OmniAuth.config.test_mode
    @previous_allowed_request_methods = OmniAuth.config.allowed_request_methods
    @previous_request_validation_phase = OmniAuth.config.request_validation_phase

    OmniAuth.config.test_mode = false
    OmniAuth.config.allowed_request_methods = [:post]
    OmniAuth.config.request_validation_phase = nil
  end

  def teardown
    OmniAuth.config.test_mode = @previous_test_mode
    OmniAuth.config.allowed_request_methods = @previous_allowed_request_methods
    OmniAuth.config.request_validation_phase = @previous_request_validation_phase
    WebMock.reset!
    super
  end

  def app
    RailsIntegrationApp
  end

  def test_rails_request_and_callback_flow_returns_expected_auth_payload
    token = 'oauth-test-token'
    session_name = 'ripuk'

    stub_lastfm_session_exchange(token, session_name)
    stub_lastfm_user_info(session_name)

    post '/auth/lastfm'

    assert_equal 302, last_response.status

    authorize_uri = URI.parse(last_response['Location'])
    query = URI.decode_www_form(authorize_uri.query).each_with_object({}) do |(key, value), hash|
      (hash[key] ||= []) << value
    end

    assert_equal 'www.last.fm', authorize_uri.host
    assert_equal ['client-key'], query.fetch('api_key')

    get '/auth/lastfm/callback', { token: token }

    assert_equal 200, last_response.status

    payload = JSON.parse(last_response.body)

    assert_equal session_name, payload['uid']
    assert_equal session_name, payload['nickname']
    assert_equal 'David Stephens', payload['name']

    assert_requested(
      :get,
      'https://ws.audioscrobbler.com/2.0/',
      query: {
        'api_key' => 'client-key',
        'token' => token,
        'api_sig' => expected_signature(token),
        'method' => 'auth.getSession',
        'format' => 'json'
      },
      times: 1
    )
    assert_requested(
      :get,
      'https://ws.audioscrobbler.com/2.0/',
      query: {
        'api_key' => 'client-key',
        'user' => session_name,
        'method' => 'user.getInfo',
        'format' => 'json'
      },
      times: 1
    )
  end

  private

  def stub_lastfm_session_exchange(token, session_name)
    stub_request(:get, 'https://ws.audioscrobbler.com/2.0/')
      .with(
        query: {
          'api_key' => 'client-key',
          'token' => token,
          'api_sig' => expected_signature(token),
          'method' => 'auth.getSession',
          'format' => 'json'
        }
      )
      .to_return(
        status: 200,
        headers: { 'Content-Type' => 'application/json' },
        body: {
          session: {
            name: session_name,
            key: 'session-key'
          }
        }.to_json
      )
  end

  def stub_lastfm_user_info(session_name)
    stub_request(:get, 'https://ws.audioscrobbler.com/2.0/')
      .with(
        query: {
          'api_key' => 'client-key',
          'user' => session_name,
          'method' => 'user.getInfo',
          'format' => 'json'
        }
      )
      .to_return(
        status: 200,
        headers: { 'Content-Type' => 'application/json' },
        body: {
          user: {
            name: session_name,
            realname: 'David Stephens',
            url: 'https://www.last.fm/user/ripuk',
            image: [{ '#text' => 'https://img.large' }],
            country: 'UK',
            age: '31',
            gender: 'm'
          }
        }.to_json
      )
  end

  def expected_signature(token)
    payload = "api_keyclient-keymethodauth.getSessiontoken#{token}client-secret"
    Digest::MD5.hexdigest(payload)
  end
end
