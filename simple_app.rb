# BasicWebApp - Rails template for applications
# Help from templates at at http://github.com/jeremymcanally/rails-templates/tree/master

# remove tmp dirs
run "rmdir tmp/{pids,sessions,sockets,cache}"

# remove unnecessary stuff
run "rm README log/*.log public/index.html public/images/rails.png"

# keep empty dirs
run("find . \\( -type d -empty \\) -and \\( -not -regex ./\\.git.* \\) -exec touch {}/.gitignore \\;")

# init git repo
git :init

# .gitignore file
file '.gitignore', 
%q{log/*.log
log/*.pid
db/*.db
db/*.sqlite3
db/schema.rb
tmp/**/*
.DS_Store
doc/api
doc/app
config/database.yml
public/javascripts/*_[0-9]*.js
public/stylesheets/*_[0-9]*.css
public/attachments
}

# copy sample database config
run "cp config/database.yml config/database.yml.sample"

# set up plugins and common gems
plugin 'rspec', :git => 'git://github.com/dchelimsky/rspec.git', :submodule => true
plugin 'rspec-rails', :git => 'git://github.com/dchelimsky/rspec-rails.git', :submodule => true
 
gem 'mislav-will_paginate', :version => '~> 2.2.3', :lib => 'will_paginate',  :source => 'http://gems.github.com'
gem 'sqlite3-ruby', :lib => 'sqlite3'

gem 'haml'
gem 'chriseppstein-compass', :lib => 'compass'

# set up user
rake('db:sessions:create')
rake('db:migrate')

# set up session store
initializer 'session_store.rb', <<-END
ActionController::Base.session = { :session_key => '_#{(1..6).map { |x| (65 + rand(26)).chr }.join}_session', :secret => '#{(1..40).map { |x| (65 + rand(26)).chr }.join}' }
ActionController::Base.session_store = :active_record_store
  END
  
git :submodule => "init"

# setup haml and blueprint
run "haml --rails ."
run "echo -e 'y\nn\n' | compass --rails -f blueprint"

# Sort out Javascript
run "rm -f public/javascripts/*"
 
run "curl -L http://jqueryjs.googlecode.com/files/jquery-1.3.2.min.js > public/javascripts/jquery.min.js"
run "curl -L http://jqueryjs.googlecode.com/svn/trunk/plugins/form/jquery.form.js > public/javascripts/jquery.form.js"
run 'curl -L http://ajax.googleapis.com/ajax/libs/jqueryui/1.7.2/jquery-ui.min.js > public/javascripts/jquery.ui.min.js'
 
git :add => '.'
git :commit => "-a -m 'Initial commit'"

rake("gems:install", :sudo => true)

log "initialized", "application structure"