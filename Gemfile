source 'https://rubygems.org'
git_source(:github) { |repo| "https://github.com/#{repo}.git" }


if ENV["RAILS_ENV"] == "development"
  ruby '2.7.0'
elsif ENV["RAILS_ENV"] == "production"
  ruby '2.6.5'
end
# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem 'rails', '~> 6.1.4'
# Use postgresql as the database for Active Record
gem 'pg', '>= 0.18', '< 2.0'
# Use Puma as the app server
gem 'nokogiri', '~> 1.12.5'
gem 'puma', '~> 4.3'
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
#gem 'fast_jsonapi'
gem 'jsonapi-serializer'
gem 'kaminari'
gem 'rmagick'
# Reduces boot times through caching; required in config/boot.rb
gem 'bootsnap', '>= 1.4.2', require: false
gem 'searchkick'
gem 'down', '~> 5.0'
# Use Rack CORS for handling Cross-Origin Resource Sharing (CORS), making cross-origin AJAX possible
gem 'rack-cors'
gem 'whenever', require: false
gem 'capistrano'
gem 'capistrano-rails'
gem 'capistrano-passenger'
gem 'capistrano-rbenv'
gem 'wicked_pdf'
gem 'open_uri_redirections'
gem 'wkhtmltopdf-binary'
gem 'activerecord', '>= 6.0.3.5'
gem 'actionpack', '>= 6.0.3.5'
group :development, :test do
  # Call 'byebug' anywhere in the code to stop execution and get a debugger console
  # gem 'byebug', platforms: [:mri, :mingw, :x64_mingw]
  gem 'pry-rails'
  %w[rspec-core rspec-rails rspec-expectations rspec-mocks rspec-support].each do |lib|
    gem lib, :git => "https://github.com/rspec/#{lib}.git", :branch => 'master'
  end
end

group :development do
end


group :production do 
gem 'pg', '>= 0.18', '< 2.0'
gem 'rails_12factor'
gem 'lograge'
end

group :test do
  gem 'database_cleaner'
  gem 'factory_bot_rails'
  gem 'faker', :git => 'https://github.com/faker-ruby/faker.git', :branch => 'master'
end

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem 'tzinfo-data', platforms: [:mingw, :mswin, :x64_mingw, :jruby]
