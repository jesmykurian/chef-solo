package %w(lamp-mariadb10.2-php7.2 php7.2 httpd mariadb-server)

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

service 'mariadb' do
  action [:start,:enable]
end
