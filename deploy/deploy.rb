#
#   cap <role> deploy:setup
#   cap <role> deploy:check
#   cap <role> deploy:cold
#   ...
#   cap <role> deploy
#

set :application, "appname"

#
# roles
#
task :to_test do
  set :user, "user"
  set :runner, "user"
  set :deploy_to, "/home/#{user}/rails_app/#{application}"
  set :public_html, "/home/#{user}/public_html"
  set :domain, "domain.com.br"
  role :app, domain
  role :web, domain
  role :db, domain
end

task :to_prod do
  set :user, "user"
  set :runner, "user"
  set :deploy_to, "/home/#{user}/rails_app/#{application}"
  set :public_html, "/home/#{user}/public_html"
  set :domain, "domain.com.br"
  role :app, domain
  role :web, domain
  role :db, domain
end

#
# repo
#
set :user, "user"
set :scm, :none
set :repository, "/home/user/repo/app"
set :deploy_via, :copy
set :copy_exclude, %w(.git/* .svn/* log/* tmp/* .gitignore public/images/upload)
set :keep_releases, 5

#
# ssh
#
ssh_options[:paranoid] = false
default_run_options[:pty] = true
set :use_sudo, false

#
# deploy
#
namespace :deploy do

  desc "restart server"
  task :restart, :roles => :app do
    run "touch #{release_path}/tmp/restart.txt"
  end

  desc "production mode"
  task :before_symlink do
    run "cd #{release_path} && rake db:migrate RAILS_ENV=production"
  end

  task :disable, :roles => :web do
    on_rollback { rm "#{shared_path}/system/maintenance.html" }
    require 'erb'
    deadline, reason = ENV['UNTIL'], ENV['REASON']
    maintenance = ERB.new(File.read("./app/views/layouts/maintenance.html.erb")).result(binding)
    put maintenance, "#{shared_path}/system/maintenance.html", :mode => 0644
  end

end

# 
# tasks
#

desc "Cria link simbolico da pasta public e diretorios para arquivos de upload e configuração"
task :before_setup do
  run "ln -s #{deploy_to}/current/public #{public_html}/#{application}"
  run "test -d #{shared_path}/upload || mkdir -p #{shared_path}/upload"
  run "test -d #{shared_path}/config || mkdir -p #{shared_path}/config"
  upload File.join(File.dirname(__FILE__), "database.yml.production"), "#{shared_path}/config/database.yml.production"
end

namespace :log do
  desc "Visualiza log de produção" 
  task :tail, :roles => :app do
    run "tail -f #{shared_path}/log/production.log" do |channel, stream, data|
      puts  # para uma linha extra 
      puts "#{channel[:host]}: #{data}" 
      break if stream == :err    
    end
  end
end

namespace :ssh do
  desc "Faz upload da sua chave publica"
  task :upload_key, :roles => :app do
    public_key_path = File.expand_path("~/.ssh/id_rsa.pub")
    unless File.exists?(public_key_path)
      puts %{
        Chave publica nao encontrada em #{public_key_path}
        Crie sua chave - sem passphrase - com o comando:
          ssh_keygen -t rsa
      }
      exit 0
    end
    ssh_path = "/home/#{user}/.ssh"
    run "test -d #{ssh_path} || mkdir -m 755 #{ssh_path}"
    upload public_key_path, "#{ssh_path}/../id_rsa.pub"
    run "test -f #{ssh_path}/authorized_keys || touch #{ssh_path}/authorized_keys"
    run "cat #{ssh_path}/../id_rsa.pub >> #{ssh_path}/authorized_keys"
    run "chmod 755 #{ssh_path}/authorized_keys"
  end
end

namespace :assets do
  desc "Manipula arquivos de configuração e upload"
  task :symlink, :roles => :app do
    assets.create_dir
    run <<-CMD
      rm -rf #{current_path}/public/images/upload &&
      rm -f #{current_path}/config/database.yml &&
      ln -nfs #{shared_path}/upload #{release_path}/public/images/upload &&
      ln -nfs #{shared_path}/config/database.yml.production #{release_path}/config/database.yml
    CMD
  end
  
  desc "Cria pastas dentro de shared"
  task :create_dir, :roles => :app do
    run "test -d #{shared_path}/upload || mkdir -p #{shared_path}/upload"
    run "test -d #{shared_path}/config || mkdir -p #{shared_path}/config"
  end
end
 
after "deploy:update_code","assets:symlink"
