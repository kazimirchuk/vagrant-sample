#!/bin/bash -i

echo "Provisioning virtual machine..."

ROOT_DIR=/home/vagrant/projects/project-name

MYSQL_VERSION=5.7
POSTGRES_VERSION=9.3
DB_NAME='random-name'
DB_USER='root'
DB_PORT='3306'
DB_PASSWORD='12345678'

NODE_VERSION=5.0

echo "Repository update..."
echo vagrant | sudo -S apt-get update > /dev/null 2>&1

echo "Installing basic things..."
echo vagrant | sudo -S apt-get install git python-software-properties build-essential -y > /dev/null 2>&1
echo vagrant | sudo -S touch /var/lib/cloud/instance/locale-check.skip
echo 'export LC_CTYPE=en_US.UTF-8' >> /home/vagrant/.bashrc
echo 'export LC_ALL=en_US.UTF-8' >> /home/vagrant/.bashrc

echo "Installing node..."
git clone https://github.com/creationix/nvm.git ~/.nvm && cd ~/.nvm && git checkout `git describe --abbrev=0 --tags` > /dev/null 2>&1
echo 'export NVM_DIR="$HOME/.nvm"' >> /home/vagrant/.bashrc
echo '[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"' >> /home/vagrant/.bashrc
source /home/vagrant/.bashrc
source /home/vagrant/.nvm/nvm.sh
nvm install $NODE_VERSION > /dev/null 2>&1
nvm alias default $NODE_VERSION > /dev/null 2>&1
nvm use default > /dev/null 2>&1

echo "Installing sass & compass..."
echo vagrant | sudo -S apt-get install -y ruby-dev > /dev/null 2>&1
echo 'export PATH=$PATH:/home/vagrant/.gem/ruby/1.9.1/bin' >> /home/vagrant/.bashrc
source /home/vagrant/.bashrc
gem install sass --user-install > /dev/null 2>&1
gem install compass --user-install > /dev/null 2>&1

echo "Installing nginx..."
echo vagrant | sudo -S apt-get install -y nginx > /dev/null 2>&1
echo vagrant | sudo -S cp $ROOT_DIR/nginx_vhost /etc/nginx/sites-available/nginx_vhost > /dev/null 2>&1
echo vagrant | sudo -S ln -s /etc/nginx/sites-available/nginx_vhost /etc/nginx/sites-enabled/
echo vagrant | sudo -S rm -rf /etc/nginx/sites-available/default
echo vagrant | sudo -S service nginx restart > /dev/null 2>&1

echo "Installing mysql..."
echo vagrant | sudo -S apt-get install -y debconf-utils > /dev/null 2>&1
echo vagrant | sudo -S debconf-set-selections <<< "mysql-server mysql-server/root_password password $DB_PASSWORD"
echo vagrant | sudo -S debconf-set-selections <<< "mysql-server mysql-server/root_password_again password $DB_PASSWORD"
echo vagrant | sudo -S apt-get -y install mysql-server > /dev/null 2>&1
echo vagrant | sudo -S sed -i "s/^bind-address.*127.0.0.1/bind-address=0.0.0.0/" /etc/mysql/my.cnf
mysql -uroot -p${DB_PASSWORD} -e "CREATE DATABASE $DB_NAME" > /dev/null 2>&1
mysql -uroot -p${DB_PASSWORD} -e "grant all privileges on $DB_NAME.* to '$DB_USER'@'localhost' identified by '$DB_PASSWORD'" > /dev/null 2>&1
echo vagrant | sudo -S service mysql restart > /dev/null 2>&1

echo "Installing postgres..."
echo vagrant | sudo -S apt-get install -y libpq-dev > /dev/null 2>&1
echo vagrant | sudo -S apt-get install -y postgresql=$POSTGRES_VERSION\* > /dev/null 2>&1
echo vagrant | sudo -S -u postgres psql -c "CREATE ROLE $DB_USER LOGIN UNENCRYPTED PASSWORD '$DB_PASSWORD' NOSUPERUSER INHERIT NOCREATEDB NOCREATEROLE NOREPLICATION;" > /dev/null 2>&1
echo vagrant | sudo -S -u postgres psql -c "CREATE DATABASE $DB_NAME" > /dev/null 2>&1
echo vagrant | sudo -S sed -i 's@#listen_addresses@listen_addresses@' /etc/postgresql/$POSTGRES_VERSION/main/postgresql.conf

echo "Installing php7"
echo vagrant | sudo -S apt-add-repository ppa:ondrej/php > /dev/null 2>&1
echo vagrant | sudo -S apt-get update > /dev/null 2>&1
echo vagrant | sudo -S apt-get install php7.0 php7.0-fpm php7.0-xml php7.0-mysql -y > /dev/null 2>&1
echo vagrant | sudo -S sed -i 's@user = www-data@user = vagrant@g' /etc/php/7.0/fpm/pool.d/www.conf
echo vagrant | sudo -S sed -i 's@group = www-data@group = vagrant@g' /etc/php/7.0/fpm/pool.d/www.conf
echo vagrant | sudo -S sed -i 's@;date.timezone =@date.timezone = "Europe\/Kiev"@g' /etc/php/7.0/cli/php.ini
echo vagrant | sudo -S service php7.0-fpm restart > /dev/null 2>&1

echo "Installing composer..."
curl -sS https://getcomposer.org/installer | php > /dev/null 2>&1
echo vagrant | sudo -S mv composer.phar /usr/local/bin/composer > /dev/null 2>&1
