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
TXT
 
# cria copias do arquivo database.yml
run "cp config/database.yml config/database.yml.sample"
run "cp config/database.yml config/database.yml.production"
 
# Rspec
if USE_RSPEC = yes?("Do you want to use RSpec for testing? (yes or no)")
  append_file TEST_FILE, %(\n\nconfig.gem "rspec", :lib => false)
  append_file TEST_FILE, %(\nconfig.gem "rspec-rails", :lib => false)
end
 
# remove arquivos desnecessários
run "rm public/index.html"
run "rm public/favicon.ico"
run "rm README"
run "rm doc/README_FOR_APP"
 
# baixa arquivo de locale pt-BR
file "config/locales/pt-BR.yml", open("http://github.com/jtadeulopes/app-template/raw/master/locale/pt-BR.yml").read
 
# define a rota default da app
route %(map.root :controller => "home")
 
# gera um controller home
generate :controller, "home", "index"
 
# instala plugins
if USE_PAPERCLIP = yes?("Install plugin paperclip? (yes or no)")
  plugin "paperclip", :git => "git://github.com/thoughtbot/paperclip.git"
end
plugin "jrails", :git => "git://github.com/aaronchi/jrails.git" if yes?("Install plugin jrails? (yes or no)")
plugin "restful_authentication", :git => "git://github.com/technoweenie/restful-authentication.git" if yes?("Install plugin restful-authentication? (yes or no)")
plugin "nifty-generators", :git => "git://github.com/jtadeulopes/nifty-generators.git" if yes?("Install plugin nifty-generators? (yes or no)")
plugin "booleanize", :git => "git://github.com/cassiomarques/booleanize.git" if yes?("Install plugin booleanize? (yes or no)")
plugin "i18n_label", :git => "git://github.com/iain/i18n_label.git" if yes?("Install plugin i18n_label? (yes or no)")
 
# define o locale default
environment %(config.i18n.default_locale = "pt-BR")
 
# rspec
if USE_RSPEC

  # gera esqueleto do rspec
  generate :rspec

  # remarkable
  if yes?("Use Remarkable? (yes or no)")
    # baixa arquivo locale pt-BR para o remarkable
    file "config/locales/pt-BR-remarkable.yml", open("http://github.com/jtadeulopes/app-template/raw/master/locale/pt-BR-remarkable.yml").read
    # configurações para o remarkable 
    append_file TEST_FILE, %(\nconfig.gem "remarkable_rails", :lib => false)
    gsub_file 'spec/spec_helper.rb', /(require 'spec\/rails'.*)/, "\\1\nrequire 'remarkable_rails'"
    # remarkable plugin para testar upload com paperclip
    plugin "remarkable_paperclip", :git => "git://github.com/dcrec1/remarkable_paperclip.git" if USE_PAPERCLIP
  end

  # Machinist
  if yes?("Use Machinist? (yes or no)")
    # configurações
    append_file TEST_FILE, %(\nconfig.gem 'notahat-machinist', :lib => 'machinist', :source => 'http://gems.github.com')
    gsub_file 'spec/spec_helper.rb', /(require 'remarkable_rails'.*)/, "\\1\nrequire File.join(File.dirname(__FILE__), 'blueprints')"
    # cria arquivo blueprint
    file "spec/blueprints.rb", <<-TXT
require 'machinist/active_record'
# blueprints
    TXT
  end

end 

# gems

# Authlogic
if yes?("Use Authlogic for authentication?") 
  gem "authlogic" 
  file "config/locales/pt-BR-authlogic.yml", open("http://github.com/jtadeulopes/app-template/raw/master/locale/pt-BR-authlogic.yml").read
end
gem "searchlogic" if yes?(" Install gem Searchlogic? (yes or no)")
gem "brazilian-rails" if yes?(" Install gem brazilian-rails? (yes or no)")

rake "gems:install", :sudo => true
rake "gems:install", :env => "test", :sudo => true

# capistrano
if yes?("Should I run capify? (yes or no)")
  capify! 
  run "rm config/deploy.rb"
  file "config/deploy.rb", open("http://github.com/jtadeulopes/app-template/raw/master/deploy/deploy.rb").read
end
 
# freeze rails edge
freeze! if yes?("Should I freeze Rails Edge? (yes or no)")

# ignore password logging
gsub_file "app/controllers/application_controller.rb", /# *(filter_parameter_logging :password)/sm, '\1'
