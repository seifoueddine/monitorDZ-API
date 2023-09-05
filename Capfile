# frozen_string_literal: true

# Load DSL and set up stages
require 'capistrano/setup'

# Include default deployment tasks

# Load the SCM plugin appropriate to your project:
#
# require "capistrano/scm/hg"
# install_plugin Capistrano::SCM::Hg
# or
# require "capistrano/scm/svn"
# install_plugin Capistrano::SCM::Svn
# or
require 'capistrano/deploy'
require 'capistrano/scm/git'
require 'capistrano/bundler'
require 'capistrano/rails/migrations'
require 'capistrano/passenger'
require 'capistrano/rbenv'
require 'whenever/capistrano'
# require 'capistrano/puma'
set :rbenv_type, 'root'
set :rbenv_ruby, '2.6.10'
install_plugin Capistrano::SCM::Git
# install_plugin Capistrano::Puma
# install_plugin Capistrano::Puma::Systemd
set :whenever_command, 'bundle exec whenever'

# Include tasks from other gems included in your Gemfile
#
# For documentation on these, see for example:
#
#   https://github.com/capistrano/rvm
#   https://github.com/capistrano/rbenv
#   https://github.com/capistrano/chruby
#   https://github.com/capistrano/bundler
#   https://github.com/capistrano/rails
#   https://github.com/capistrano/passenger

# require "capistrano/rvm"
# require "capistrano/rbenv"
# require "capistrano/chruby"
# require "capistrano/bundler"
# require "capistrano/rails/assets"
# require "capistrano/rails/migrations"
# require "capistrano/passenger"

# Load custom tasks from `lib/capistrano/tasks` if you have any defined
Dir.glob('lib/capistrano/tasks/*.rake').each { |r| import r }
