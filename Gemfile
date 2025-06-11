source "https://rubygems.org"

# Force modern Bundler version for Ruby 3.4+ compatibility
ruby RUBY_VERSION
gem 'bundler', '>= 2.4.0'

# setup_circle_ci action was released in 2.107.0
gem 'fastlane', '>= 2.107'
gem 'abbrev'

# Ruby 3.4+ compatibility - add standard library gems that are now separate
gem 'mutex_m'
gem 'logger'
gem 'ostruct'

# Force compatible json gem version to avoid native extension issues
gem 'json', '~> 2.7.0'
gem 'xcode-install'