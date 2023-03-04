# frozen_string_literal: true

source 'https://rubygems.org'
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

case ENV['RAILS_ENV']
when 'development'
  ruby '3.1.2'
when 'production'
  ruby '2.6.5'
end
# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem 'rails', '~> 6.1.4'
# Use postgresql as the database for Active Record
gem 'pg', '>= 0.18', '< 2.0'
# Use Puma as the app server
gem 'net-smtp', require: false
gem 'net-ssh', '7.0.0.beta1'
gem 'nokogiri', '~> 1.13.10'
gem 'puma', '~> 5.6.4'
# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
# gem 'jbuilder', '~> 2.7'
# Use Redis adapter to run Action Cable in production
# gem 'redis', '~> 4.0'
# Use Active Model has_secure_password
# gem 'bcrypt', '~> 3.1.7'
gem 'devise_token_auth'
# Use Active Storage variant
# gem 'image_processing', '~> 1.2'
gem 'carrierwave', '>= 2.1.1'
# gem 'fast_jsonapi'
gem 'jsonapi-serializer'
gem 'kaminari'
gem 'rmagick'
gem 'rubocop', require: false
# Reduces boot times through caching; required in config/boot.rb
gem 'bootsnap', '>= 1.4.2', require: false
gem 'down', '~> 5.0'
gem 'searchkick'
# Use Rack CORS for handling Cross-Origin Resource Sharing (CORS), making cross-origin AJAX possible
gem 'actionpack', '>= 6.0.3.5'
gem 'activerecord', '>= 6.0.3.5'
gem 'annotate'
gem 'capistrano'
gem 'capistrano3-puma', github: 'seuros/capistrano-puma'
gem 'capistrano-passenger'
gem 'capistrano-rails'
gem 'capistrano-rbenv'
gem 'capistrano-sidekiq'
gem 'open_uri_redirections'
gem 'rack-cors'
gem 'sidekiq'
gem 'sidekiq-cron'
gem 'whenever', require: false
gem 'wicked_pdf'
gem 'wkhtmltopdf-binary'
group :development, :test do
  # Call 'byebug' anywhere in the code to stop execution and get a debugger console
  # gem 'byebug', platforms: [:mri, :mingw, :x64_mingw]
  gem 'pry-rails'
  # %w[rspec-core rspec-rails rspec-expectations rspec-mocks rspec-support].each do |lib|
  #   gem lib, git: "https://github.com/rspec/#{lib}.git", branch: 'master'
  # end
  gem 'rspec-rails'
end

group :development do
end

group :production do
  gem 'lograge'
  gem 'rails_12factor'
end

group :test do
  gem 'database_cleaner'
  gem 'factory_bot_rails'
  gem 'faker', git: 'https://github.com/faker-ruby/faker.git', branch: 'master'
  gem 'simplecov', require: false
end

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem 'tzinfo-data', platforms: %i[mingw mswin x64_mingw jruby]
