# Gem Bundler template with help from github.com/tomafro/dotfiles templates
# Modified to support Bundler 0.9
#
# creates a script/bundler that can be ran within the created project

inside '.bundler/bundler' do  
  run 'git init'
  run 'git pull --depth 1 git://github.com/carlhuda/bundler.git' 
  run 'rm -rf .git .gitignore'
end

file 'script/bundler', %{
#!/usr/bin/env ruby
$LOAD_PATH.unshift File.expand_path(File.join(File.dirname(__FILE__), "..", ".bundler/bundler/lib"))
require 'rubygems'
require 'rubygems/command'
require 'bundler'
require 'bundler/cli'
begin
  Bundler::CLI.start
rescue Bundler::BundlerError => e
  Bundler.ui.error e.message
  exit e.status_code
end
}.strip

run 'chmod +x script/bundler'

file 'Gemfile', %{
source :gemcutter

gem 'rails', '#{Rails::VERSION::STRING}', :require => nil
gem "sqlite3-ruby", :require => "sqlite3"

group :test do
  gem 'ruby-debug'
  #gem 'shoulda'
  #gem 'factory_girl'
end
}.strip
  
append_file '.gitignore', %{
log/*.log
log/*.pid
db/*.db
db/*.sqlite3
db/schema.rb
tmp/**/*
.DS_Store
config/database.yml
}

run 'script/bundler install'

append_file '/config/preinitializer.rb', %{
begin
  # Require the preresolved locked set of gems.
  require File.expand_path('../../.bundler/environment', __FILE__)
rescue LoadError
  # Fallback on doing the resolve at runtime.
  $LOAD_PATH.unshift File.expand_path(File.join(File.dirname(__FILE__), "..", ".bundler/bundler/lib"))
  require "rubygems"
  require "bundler"
  Bundler.setup
end
}

gsub_file 'config/boot.rb', "Rails.boot!", %{
  # add gem bundler 
  class Rails::Boot
    def run
      load_initializer
      extend_environment
      Rails::Initializer.run(:set_load_path)
    end

    def extend_environment
      Rails::Initializer.class_eval do
        old_load = instance_method(:load_environment)
        define_method(:load_environment) do
          Bundler.require :default, Rails.env
          old_load.bind(self).call
        end
      end
    end
  end

  Rails.boot!
}

# init git repo
git :init

# copy sample database config
run "cp config/database.yml config/database.yml.sample"

# set up sessions
rake('db:sessions:create')
rake('db:migrate')

# Remove files not needed
run "rm -f public/javascripts/*"
run "rm public/index.html"

# set up session store
initializer 'session_store.rb', <<-END
ActionController::Base.session = { :session_key => '_#{(1..6).map { |x| (65 + rand(26)).chr }.join}_session', :secret => '#{(1..40).map { |x| (65 + rand(26)).chr }.join}' }
ActionController::Base.session_store = :active_record_store
  END
  
git :add => '.'
git :commit => "-a -m 'Initial commit'"