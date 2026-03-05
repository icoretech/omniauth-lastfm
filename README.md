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

Example payload available in `request.env['omniauth.auth']` (real flow shape, anonymized):

```json
{
  "provider": "lastfm",
  "uid": "sample_user",
  "info": {
    "nickname": "sample_user",
    "name": "Sample User",
    "url": "https://www.last.fm/user/sample_user",
    "image": "https://lastfm.freetls.fastly.net/i/u/300x300/sample-image-id.png",
    "country": "Neverland",
    "age": "0",
    "gender": "n"
  },
  "credentials": {
    "token": "sample-session-key",
    "name": "sample_user"
  },
  "extra": {
    "raw_info": {
      "name": "sample_user",
      "age": "0",
      "subscriber": "0",
      "realname": "Sample User",
      "bootstrap": "0",
      "playcount": "49612",
      "artist_count": "399",
      "playlists": "0",
      "track_count": "5271",
      "album_count": "690",
      "image": [
        {
          "size": "small",
          "#text": "https://lastfm.freetls.fastly.net/i/u/34s/sample-image-id.png"
        },
        {
          "size": "medium",
          "#text": "https://lastfm.freetls.fastly.net/i/u/64s/sample-image-id.png"
        },
        {
          "size": "large",
          "#text": "https://lastfm.freetls.fastly.net/i/u/174s/sample-image-id.png"
        },
        {
          "size": "extralarge",
          "#text": "https://lastfm.freetls.fastly.net/i/u/300x300/sample-image-id.png"
        }
      ],
      "registered": {
        "unixtime": "1257061701",
        "#text": 1257061701
      },
      "country": "Neverland",
      "gender": "n",
      "url": "https://www.last.fm/user/sample_user",
      "type": "user"
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
