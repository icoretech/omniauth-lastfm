# frozen_string_literal: true

lib = File.expand_path("lib", __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "omniauth/lastfm/version"

Gem::Specification.new do |spec|
  spec.name = "omniauth-lastfm"
  spec.version = OmniAuth::Lastfm::VERSION
  spec.authors = ["Claudio Poli"]
  spec.email = ["masterkain@gmail.com"]

  spec.summary = "OmniAuth strategy for Last.fm authentication."
  spec.description = "OAuth strategy for OmniAuth that authenticates users with Last.fm and exposes profile metadata."
  spec.homepage = "https://github.com/icoretech/omniauth-lastfm"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.2"

  spec.metadata["source_code_uri"] = "https://github.com/icoretech/omniauth-lastfm"
  spec.metadata["bug_tracker_uri"] = "https://github.com/icoretech/omniauth-lastfm/issues"
  spec.metadata["changelog_uri"] = "https://github.com/icoretech/omniauth-lastfm/releases"
  spec.metadata["rubygems_mfa_required"] = "true"

  spec.files = Dir[
    "lib/**/*.rb",
    "README*",
    "LICENSE*",
    "*.gemspec"
  ]
  spec.require_paths = ["lib"]

  spec.add_dependency "omniauth", ">= 2.1", "< 3.0"
end
