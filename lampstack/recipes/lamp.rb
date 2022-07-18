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
  members 'ec2-user'
  append true
end

bash 'var-www-perms' do
  user 'root'
  cwd '/tmp'
  code <<-EOH
  chown -R root:apache /var/www
  chmod 2775 /var/www
  find /var/www -type d -exec chmod 2775 {} \\;
  find /var/www -type f -exec chmod 0664 {} \\;
  EOH
end

file '/var/www/html/phpinfo.php' do
  content '<html><body><h1>My first PHP page</h1><?php echo "Hello World!";?> </body></html>'
  mode '0755'
  owner 'ec2-user'
  group 'apache'
end

service 'mariadb' do
  action [:start,:enable]
  only_if { node['lampstack']['mariadb']['install_sql'] }
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
    expect \\"Change the root password?\\"
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
  only_if { node['lampstack']['mariadb']['install_sql'] }
end

ruby_block 'set install_sql' do
  block do
    node.force_default['lampstack']['mariadb']['install_sql'] = false
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

#remote_file '/var/www/html/phpMyAdmin.tar.gz' do
#  source 'https://www.phpmyadmin.net/downloads/phpMyAdmin-latest-all-languages.tar.gz'
#  owner 'ec2-user'
#  group 'apache'
#  mode '0755'
#  ssl_verify_mode :verify_none
#  action :create
#end

directory '/var/www/html/phpMyAdmin' do
  owner 'ec2-user'
  group 'apache'
  mode '0755'
  action :create
end

#archive_file 'phpMyAdmin.tar.gz' do
#  owner 'ec2-user'
#  group 'apache'
#  mode '700'
#  path '/tmp/code/phpMyAdmin.tar.gz'
#  destination '/var/www/html/phpMyAdmin'
#end

bash 'var-www-perms' do
  user 'ec2-user'
  cwd '/var/www/html/phpMyAdmin'
  code <<-EOH
  tar -xvzf /tmp/code/phpMyAdmin.tar.gz -C phpMyAdmin --strip-components 1;
  EOH
end
