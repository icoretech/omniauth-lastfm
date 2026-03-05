# frozen_string_literal: true

require 'digest/md5'
require 'json'
require 'net/http'
require 'omniauth'
require 'uri'

module OmniAuth
  module Strategies
    # OmniAuth strategy for Last.fm authentication.
    class Lastfm
      include OmniAuth::Strategy

      args %i[api_key secret_key]

      option :name, 'lastfm'
      option :api_key, nil
      option :secret_key, nil
      option :api_timeout, 10
      option :client_options,
             site: 'https://www.last.fm',
             authorize_path: '/api/auth',
             api_url: 'https://ws.audioscrobbler.com/2.0/',
             user_agent: 'icoretech-omniauth-lastfm gem'

      uid { session_data['name'] }

      info do
        {
          nickname: user_data['name'],
          name: user_data['realname'],
          url: user_data['url'],
          image: image_url(user_data['image']),
          country: user_data['country'],
          age: user_data['age'],
          gender: user_data['gender']
        }.compact
      end

      extra do
        {
          'raw_info' => user_data
        }
      end

      credentials do
        {
          token: session_data['key'],
          name: session_data['name']
        }.compact
      end

      def request_phase
        authorize_url = "#{options.client_options.site}#{options.client_options.authorize_path}"
        query_string = URI.encode_www_form(request_phase_params)
        redirect("#{authorize_url}?#{query_string}")
      end

      def callback_phase
        load_profile!
        super
      rescue StandardError => e
        fail!(:invalid_credentials, e)
      end

      protected

      def load_profile!
        token = request.params['token'].to_s
        raise ArgumentError, 'Missing token parameter in callback request' if token.empty?

        session_payload = fetch_json(session_params(token))
        user_name = session_payload.dig('session', 'name').to_s
        raise ArgumentError, 'Missing session name in Last.fm session response' if user_name.empty?

        @json = session_payload
        @json.merge!(fetch_json(user_info_params(user_name)))
      end

      def fetch_json(params)
        uri = URI(options.client_options.api_url)
        uri.query = URI.encode_www_form(params)

        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = uri.scheme == 'https'
        http.open_timeout = options.api_timeout
        http.read_timeout = options.api_timeout

        request = Net::HTTP::Get.new(uri.request_uri)
        request['Accept'] = 'application/json'
        request['User-Agent'] = options.client_options.user_agent

        response = http.request(request)
        unless response.is_a?(Net::HTTPSuccess)
          raise LastfmApiError, "Last.fm API request failed (status #{response.code})"
        end

        JSON.parse(response.body)
      rescue JSON::ParserError => e
        raise LastfmApiError, "Last.fm API returned invalid JSON: #{e.message}"
      end

      def session_data
        @json&.fetch('session', {}) || {}
      end

      def user_data
        @json&.fetch('user', {}) || {}
      end

      def image_url(value)
        case value
        when Array
          value.reverse_each do |entry|
            image = entry.fetch('#text', '').to_s
            return image unless image.empty?
          end
          nil
        when Hash
          image = value.fetch('#text', '').to_s
          image.empty? ? nil : image
        else
          image = value.to_s
          image.empty? ? nil : image
        end
      end

      def request_phase_params
        {
          api_key: options.api_key,
          cb: callback_url
        }
      end

      def session_params(token)
        {
          api_key: options.api_key,
          token: token,
          api_sig: signature(token),
          method: 'auth.getSession',
          format: 'json'
        }
      end

      def user_info_params(user_name)
        {
          api_key: options.api_key,
          user: user_name,
          method: 'user.getInfo',
          format: 'json'
        }
      end

      def signature(token)
        base = "api_key#{options.api_key}methodauth.getSessiontoken#{token}#{options.secret_key}"
        Digest::MD5.hexdigest(base)
      end

      class LastfmApiError < StandardError; end
    end
  end
end
