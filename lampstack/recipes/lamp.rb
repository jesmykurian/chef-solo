sql_pw = ENV['maria_pw']

package %w(httpd mariadb-server expect.x86_64)

bash 'amazon-extras-install' do
  user 'root'
  cwd '/tmp'
  code <<-EOH
  amazon-linux-extras install -y lamp-mariadb10.2-php7.2 php7.2
  EOH
end

service 'httpd' do
  action [:start,:enable]
end

group 'apache' do
  action :create
end

group 'apache' do
  action :modify
  members node['lampstack']['user']
  append true
end

bash 'var-www-perms' do
  user 'root'
  cwd '/tmp'
  code <<-EOH
  chown -R #{node['lampstack']['user']}:#{node['lampstack']['group']} /var/www
  chmod 2775 /var/www
  find /var/www -type d -exec chmod 2775 {} \\;
  find /var/www -type f -exec chmod 0664 {} \\;
  EOH
end

service 'mariadb' do
  action [:start,:enable]
  only_if { node['lampstack']['install_sql'] }
end

bash 'mariadb-install' do
  user 'root'
  cwd '/tmp'
  code <<-EOH
    expect -c "
    set timeout 10
    spawn mysql_secure_installation
    expect \\"Enter current password for root (enter for none):\\"
    send \\"\r\\"
    expect \\"Change the root password? * \\"
    send \\"y\r\\"
    expect \\"New password:\\"
    send \\"#{sql_pw}\r\\"
    expect \\"Re-enter new password:\\"
    send \\"#{sql_pw}\r\\"
    expect \\"Remove anonymous users?\\"
    send \\"y\r\\"
    expect \\"Disallow root login remotely?\\"
    send \\"y\r\\"
    expect \\"Remove test database and access to it?\\"
    send \\"y\r\\"
    expect \\"Reload privilege tables now?\\"
    send \\"y\r\\"
    expect eof"
  EOH
  only_if { node['lampstack']['install_sql'] }
end

ruby_block 'set install_sql' do
  block do
    node.normal['lampstack']['install_sql'] = false
    node.save
  end
  action :run
end

package %w(php-mbstring php-xml)

service 'httpd' do
  action [:restart]
end

service 'php-fpm' do
  action [:restart]
end

directory '/var/www/html/phpMyAdmin' do
  recursive true
  action :delete
end

directory '/var/www/html/phpMyAdmin' do
  owner node['lampstack']['user']
  group node['lampstack']['group']
  mode '0755'
  action :create
end

bash 'download' do
  user node['lampstack']['user']
  cwd '/var/www/html/phpMyAdmin'
  code <<-EOH
  wget https://www.phpmyadmin.net/downloads/phpMyAdmin-latest-all-languages.tar.gz
  tar -xvzf phpMyAdmin-latest-all-languages.tar.gz --strip-components 1
  rm -rf phpMyAdmin-latest-all-languages.tar.gz
  EOH
end

remote_directory '/var/www/html/phpMyAdmin' do
  source '/tmp/phpMyAdmin'
  owner 'ec2-user'
  group 'apache'
  mode '0755'
  action :create
end

template '/var/www/html/phpMyAdmin/doc/html/index.html' do
  source "index.html.erb"
  action :create
  variables ({
    :myTitle => node['lampstack']['title']
  })
end



