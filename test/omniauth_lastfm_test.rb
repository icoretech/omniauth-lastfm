# frozen_string_literal: true

require_relative 'test_helper'

require 'uri'

class OmniauthLastfmTest < Minitest::Test
  def build_strategy
    OmniAuth::Strategies::Lastfm.new(nil, 'client-key', 'client-secret')
  end

  def test_uses_current_lastfm_endpoints
    client_options = build_strategy.options.client_options

    assert_equal 'https://www.last.fm', client_options.site
    assert_equal '/api/auth', client_options.authorize_path
    assert_equal 'https://ws.audioscrobbler.com/2.0/', client_options.api_url
  end

  def test_uid_info_extra_and_credentials_are_derived_from_loaded_profile
    strategy = build_strategy
    strategy.instance_variable_set(
      :@json,
      {
        'session' => { 'name' => 'ripuk', 'key' => 'session-key' },
        'user' => {
          'name' => 'ripuk',
          'realname' => 'David Stephens',
          'url' => 'https://www.last.fm/user/ripuk',
          'image' => [{ '#text' => 'https://img.small' }, { '#text' => 'https://img.large' }],
          'country' => 'UK',
          'age' => '31',
          'gender' => 'm'
        }
      }
    )

    assert_equal 'ripuk', strategy.uid
    assert_equal(
      {
        nickname: 'ripuk',
        name: 'David Stephens',
        url: 'https://www.last.fm/user/ripuk',
        image: 'https://img.large',
        country: 'UK',
        age: '31',
        gender: 'm'
      },
      strategy.info
    )
    assert_equal({ 'raw_info' => strategy.instance_variable_get(:@json)['user'] }, strategy.extra)
    assert_equal({ token: 'session-key', name: 'ripuk' }, strategy.credentials)
  end

  def test_uid_info_extra_and_credentials_match_live_lastfm_payload_shape
    strategy = build_strategy
    strategy.instance_variable_set(
      :@json,
      {
        'session' => { 'name' => 'sample_user', 'key' => 'sample-session-key' },
        'user' => {
          'name' => 'sample_user',
          'age' => '0',
          'subscriber' => '0',
          'realname' => 'Sample User',
          'bootstrap' => '0',
          'playcount' => '49612',
          'artist_count' => '399',
          'playlists' => '0',
          'track_count' => '5271',
          'album_count' => '690',
          'image' => [
            {
              'size' => 'small',
              '#text' => 'https://lastfm.freetls.fastly.net/i/u/34s/sample-image-id.png'
            },
            {
              'size' => 'medium',
              '#text' => 'https://lastfm.freetls.fastly.net/i/u/64s/sample-image-id.png'
            },
            {
              'size' => 'large',
              '#text' => 'https://lastfm.freetls.fastly.net/i/u/174s/sample-image-id.png'
            },
            { 'size' => 'extralarge', '#text' => 'https://lastfm.freetls.fastly.net/i/u/300x300/sample-image-id.png' }
          ],
          'registered' => { 'unixtime' => '1257061701', '#text' => 1_257_061_701 },
          'country' => 'Neverland',
          'gender' => 'n',
          'url' => 'https://www.last.fm/user/sample_user',
          'type' => 'user'
        }
      }
    )

    assert_equal 'sample_user', strategy.uid
    assert_equal(
      {
        nickname: 'sample_user',
        name: 'Sample User',
        url: 'https://www.last.fm/user/sample_user',
        image: 'https://lastfm.freetls.fastly.net/i/u/300x300/sample-image-id.png',
        country: 'Neverland',
        age: '0',
        gender: 'n'
      },
      strategy.info
    )
    assert_equal({ 'raw_info' => strategy.instance_variable_get(:@json)['user'] }, strategy.extra)
    assert_equal({ token: 'sample-session-key', name: 'sample_user' }, strategy.credentials)
  end

  def test_signature_matches_lastfm_oauth_expectation
    strategy = build_strategy

    assert_equal 'c01a8f58dd416ca25557a69c7ca5ffe7', strategy.send(:signature, 'oauth-token')
  end

  def test_load_profile_fetches_session_then_user
    strategy = build_strategy
    request = Rack::Request.new(Rack::MockRequest.env_for('/auth/lastfm/callback?token=oauth-token'))
    strategy.define_singleton_method(:request) { request }

    calls = []
    strategy.define_singleton_method(:fetch_json) do |params|
      calls << params
      if params[:method] == 'auth.getSession'
        { 'session' => { 'name' => 'ripuk', 'key' => 'session-key' } }
      else
        { 'user' => { 'name' => 'ripuk' } }
      end
    end

    strategy.send(:load_profile!)

    assert_equal 2, calls.length
    assert_equal 'auth.getSession', calls.first[:method]
    assert_equal 'user.getInfo', calls.last[:method]
    assert_equal 'ripuk', strategy.uid
  end

  def test_load_profile_requires_callback_token
    strategy = build_strategy
    request = Rack::Request.new(Rack::MockRequest.env_for('/auth/lastfm/callback'))
    strategy.define_singleton_method(:request) { request }

    assert_raises(ArgumentError) { strategy.send(:load_profile!) }
  end

  def test_request_phase_redirects_to_lastfm_auth_with_callback
    previous_request_validation_phase = OmniAuth.config.request_validation_phase
    OmniAuth.config.request_validation_phase = nil

    app = ->(_env) { [404, { 'Content-Type' => 'text/plain' }, ['not found']] }
    strategy = OmniAuth::Strategies::Lastfm.new(app, 'client-key', 'client-secret')
    env = Rack::MockRequest.env_for('/auth/lastfm', method: 'POST')
    env['rack.session'] = {}

    status, headers, = strategy.call(env)

    assert_equal 302, status

    location = URI.parse(headers['Location'])
    params = URI.decode_www_form(location.query).each_with_object({}) do |(key, value), hash|
      (hash[key] ||= []) << value
    end

    assert_equal 'www.last.fm', location.host
    assert_equal ['/auth/lastfm/callback'], [URI.parse(params.fetch('cb').first).path]
    assert_equal ['client-key'], params.fetch('api_key')
  ensure
    OmniAuth.config.request_validation_phase = previous_request_validation_phase
  end

  def test_request_phase_uses_configured_callback_url
    previous_request_validation_phase = OmniAuth.config.request_validation_phase
    OmniAuth.config.request_validation_phase = nil

    app = ->(_env) { [404, { 'Content-Type' => 'text/plain' }, ['not found']] }
    callback = 'https://example.test/account/auth/windowslive/callback'
    strategy = OmniAuth::Strategies::Lastfm.new(
      app,
      'client-key',
      'client-secret',
      callback_url: callback
    )
    env = Rack::MockRequest.env_for('/auth/lastfm', method: 'POST')
    env['rack.session'] = {}

    status, headers, = strategy.call(env)

    assert_equal 302, status

    location = URI.parse(headers['Location'])
    params = URI.decode_www_form(location.query).to_h

    assert_equal callback, params.fetch('cb')
  ensure
    OmniAuth.config.request_validation_phase = previous_request_validation_phase
  end
end
