# OmniAuth Last.fm

[![Test](https://github.com/icoretech/omniauth-lastfm/actions/workflows/test.yml/badge.svg?branch=main)](https://github.com/icoretech/omniauth-lastfm/actions/workflows/test.yml)
[![Gem Version](https://img.shields.io/gem/v/omniauth-lastfm.svg)](https://rubygems.org/gems/omniauth-lastfm)

`omniauth-lastfm` is an OmniAuth strategy for authenticating with Last.fm.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'omniauth-lastfm'
```

Then run:

```bash
bundle install
```

## Usage

Configure OmniAuth in your initializer:

```ruby
Rails.application.config.middleware.use OmniAuth::Builder do
  provider :lastfm, ENV.fetch('LASTFM_API_KEY'), ENV.fetch('LASTFM_SECRET_KEY')
end
```

Set callback URL in the Last.fm API application settings:

- `https://your-app.example.com/auth/lastfm/callback`

## Auth Hash

Example payload available in `request.env['omniauth.auth']`:

```json
{
  "provider": "lastfm",
  "uid": "ripuk",
  "info": {
    "nickname": "ripuk",
    "name": "David Stephens",
    "url": "https://www.last.fm/user/ripuk",
    "image": "https://lastfm.freetls.fastly.net/i/u/300x300/abcdef.jpg",
    "country": "UK",
    "age": "31",
    "gender": "m"
  },
  "credentials": {
    "token": "abcdefghijklmnop",
    "name": "ripuk"
  },
  "extra": {
    "raw_info": {
      "name": "ripuk"
    }
  }
}
```

## Development

Run lint and unit tests:

```bash
bundle exec rake
```

Run Rails integration tests explicitly:

```bash
RAILS_VERSION='~> 7.2.0' bundle exec rake test_rails_integration
```

## Tested Matrix

- Ruby: 3.2, 3.3, 3.4, 4.0
- Rails integration: 7.1, 7.2, 8.0, 8.1
