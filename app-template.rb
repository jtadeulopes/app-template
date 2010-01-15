TEST_FILE = "config/environments/test.rb"
 
# inicia um positorio git
git :init
 
# cria um arquivo .gitignore
file ".gitignore", <<-TXT
log/*.log
tmp/**/*
config/database.yml
config/database.yml.production
db/*.sqlite3
.DS_Store
public/images/upload
TXT
 
# cria copias do arquivo database.yml
run "cp config/database.yml config/database.yml.sample"
run "cp config/database.yml config/database.yml.production"
 
# remove arquivos desnecessários
run "rm public/index.html"
run "rm public/favicon.ico"
run "rm README"
run "rm doc/README_FOR_APP"
 
# I18n locale pt-BR
file "config/locales/pt-BR.yml", open("http://github.com/jtadeulopes/app-template/raw/master/locale/pt-BR.yml").read
 
# define a rota default da app
route %(map.root :controller => "home")
 
# gera um controller home
generate :controller, "home", "index"
 
#
# Plugins
#
if USE_PAPERCLIP = yes?("Install plugin paperclip? (yes or no)")
  plugin "paperclip", :git => "git://github.com/thoughtbot/paperclip.git"
end
plugin "jrails", :git => "git://github.com/aaronchi/jrails.git"                                     if yes?("Install plugin jrails? (yes or no)")
plugin "nifty-generators", :git => "git://github.com/jtadeulopes/nifty-generators.git"              if yes?("Install plugin nifty-generators? (yes or no)")
plugin "booleanize", :git => "git://github.com/cassiomarques/booleanize.git"                        if yes?("Install plugin booleanize? (yes or no)")
plugin "i18n_label", :git => "git://github.com/iain/i18n_label.git"                                 if yes?("Install plugin i18n_label? (yes or no)")
 
# config/environment.rb
environment %(config.i18n.default_locale = "pt-BR")
environment %(config.time_zone = "Brasilia")
 
#
# Test
#
 
# Rspec
if USE_RSPEC = yes?("Do you want to use RSpec for testing? (yes or no)")
  append_file TEST_FILE, %(\n\nconfig.gem "rspec", :lib => false)
  append_file TEST_FILE, %(\nconfig.gem "rspec-rails", :lib => false)
  append_file TEST_FILE, %(\nconfig.gem "cucumber", :lib => false)
end

if USE_RSPEC

  # gera esqueleto do rspec
  generate :rspec

  # remarkable
  if yes?("Use Remarkable? (yes or no)")

    # configurações
    append_file TEST_FILE, %(\nconfig.gem "remarkable_rails", :lib => false)
    gsub_file 'spec/spec_helper.rb', /(require 'spec\/rails'.*)/, "\\1\nrequire 'remarkable_rails'"

    # locale pt-BR
    file "config/locales/pt-BR-remarkable.yml", open("http://github.com/jtadeulopes/app-template/raw/master/locale/pt-BR-remarkable.yml").read

    # plugins
    plugin "remarkable_paperclip", :git => "git://github.com/dcrec1/remarkable_paperclip.git" if USE_PAPERCLIP
    plugin "remarkable_extensions", :git => "git://github.com/dcrec1/remarkable_extensions.git"
    plugin "remarkable_authlogic", :git => "git://github.com/daviscabral/remarkable_authlogic.git"
  end

  # machinist
  if yes?("Use Machinist? (yes or no)")

    # configurações
    append_file TEST_FILE, %(\nconfig.gem 'notahat-machinist', :lib => 'machinist', :source => 'http://gems.github.com')
    gsub_file 'spec/spec_helper.rb', /(require 'remarkable_rails'.*)/, "\\1\nrequire File.join(File.dirname(__FILE__), 'blueprints')"

    # cria arquivo blueprint
    file "spec/blueprints.rb", <<-TXT
require 'machinist/active_record'
#
# blueprints
#
=begin
User.blueprint do
  username { Faker::Internet.user_name }
  email { Faker::Internet.email }
  password 'benrocks'
  password_confirmation 'benrocks'
  password_salt { Authlogic::Random.hex_token }
  crypted_password { Authlogic::CryptoProviders::Sha512.encrypt("benrocks" + Authlogic::Random.hex_token) }
  persistence_token { Authlogic::Random.friendly_token }
end
=end
    TXT

  end

end 

#
# Gems
#
if yes?("Use Authlogic for authentication? (yes or no)") 
  gem "authlogic" 
  file "config/locales/pt-BR-authlogic.yml", open("http://github.com/jtadeulopes/app-template/raw/master/locale/pt-BR-authlogic.yml").read
end
if yes?("Install gem Formtastic? (yes or no)")
  gem "formtastic", :source  => 'http://gemcutter.org' 
  file "config/locales/pt-BR-formtastic.yml", open("http://github.com/jtadeulopes/app-template/raw/master/locale/pt-BR-formtastic.yml").read
end
gem "searchlogic"                           if yes?(" Install gem Searchlogic? (yes or no)")
gem "brazilian-rails", :version => "2.1.8"  if yes?(" Install gem brazilian-rails? (yes or no)")
gem "rack", :version => "1.0.1"             if yes?("Install gem rack? (yes or no) - Require for Locaweb")

rake "gems:install", :sudo => true
rake "gems:install", :env => "test", :sudo => true

#
# Capistrano
#
if yes?("Should I run capify? (yes or no)")
  capify! 
  run "rm config/deploy.rb"
  file "config/deploy.rb", open("http://github.com/jtadeulopes/app-template/raw/master/deploy/deploy.rb").read
end
 
# ignore password logging
gsub_file "app/controllers/application_controller.rb", /# *(filter_parameter_logging :password)/sm, '\1'
