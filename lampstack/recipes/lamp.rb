package %w(httpd mariadb-server)

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
end
