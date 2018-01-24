#!/bin/bash

echo 'Setting up your developmental environment. This may take a while.'

echo '[*] Checking for Curl...'
if ! which curl >/dev/null; then
  echo 'Curl Not Found!'
  echo '[*] Installing Curl...'
  sudo apt-get install curl
else
  echo 'Curl Found!'
fi

echo '[*] Adding keys...'
# Add keys for Yarn
curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | sudo apt-key add -
echo "deb https://dl.yarnpkg.com/debian/ stable main" | sudo tee /etc/apt/sources.list.d/yarn.list

# Add Keys for MariaDB
sudo apt-key adv --recv-keys --keyserver hkp://keyserver.ubuntu.com:80 0xF1656F24C74CD1D8
sudo add-apt-repository 'deb [arch=amd64,i386,ppc64el] http://mirror.jmu.edu/pub/mariadb/repo/10.1/ubuntu xenial main'
sudo apt-get update

echo '[*] Installing R...'
sudo apt install r-base

echo '[*] Install node.js...'
if which node | grep node >/dev/null;then
  echo 'Node already installed!'
else
  curl -sL https://deb.nodesource.com/setup_8.x | sudo -E bash -
  sudo apt-get install -y nodejs
fi

echo '[*] Installing GNUpg...'
sudo apt-get install gnupg

echo '[*] Installing yarn...'
sudo apt-get install yarn

echo '[*] Installing pandoc...'
sudo apt-get install pandoc

echo '[*] Installing redis-server...'
sudo apt install redis-server

echo '[*] Installing mariadbclient dependencies...'
sudo apt-get install libmariadbclient-dev

echo '[*] Installing Mysql-server...'
echo 'Please Setup your Root password when asked during installation!'
sudo apt-get install software-properties-common
sudo apt-get install -y mariadb-server
sudo systemctl start mariadb.service
sudo systemctl enable mariadb.service

echo "[*] Creating Databases and User for Mysql..."
echo -n 'Enter Username for New Mysql User: '
read NEWUSER
echo -n 'Enter Password for New Mysql User: '
read NEWPASSWORD
echo 'Enter password for Mysql root user'
echo "CREATE DATABASE dashboard DEFAULT CHARACTER SET utf8 DEFAULT COLLATE utf8_general_ci;
      CREATE DATABASE dashboard_testing DEFAULT CHARACTER SET utf8 DEFAULT COLLATE utf8_general_ci;
      CREATE USER '$NEWUSER'@'localhost' IDENTIFIED BY '$NEWPASSWORD';
      GRANT ALL PRIVILEGES ON dashboard . * TO '$NEWUSER'@'localhost';
      GRANT ALL PRIVILEGES ON dashboard_testing . * TO '$NEWUSER'@'localhost';
      exit" | sudo mysql -p

echo '[*] Checking for Database configurations...'
if [ -f config/database.yml ]; then
  echo 'Database configurations found.'
else
  echo 'Database configurations not found!'
  echo '[*] Creating Database configurations...'
  cp config/database.example.yml config/database.yml
fi

echo '[*] Checking for application configurations...'
if [ -f config/application.yml ]; then
  echo 'Application configurations found.'
else
  echo 'Application configurations not found!'
  echo '[*] Creating Application configurations...'
  cp config/application.example.yml config/application.yml
fi

echo '[*] Setting Database User configurations...'
sed -i -e "s/\(username: \).*/\1$NEWUSER/" \
-e "s/\(password: \).*/\1$NEWPASSWORD/" ../config/database.yml


echo '[*] Checking for rvm...'
if ! which rvm > /dev/null; then
  gpg --keyserver hkp://keys.gnupg.net --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3 7D2BAF1CF37B13E2069D6956105BD0E739499BDB && echo '[*] Installing rvm...' && \curl -sSL https://get.rvm.io | bash -s stable
  source /home/sage/.rvm/scripts/rvm
fi

echo '[*] Installing Ruby-2.5.0...'
rvm install ruby-2.5.0

echo '[*] Installing bundler...'
gem install bundler

echo '[*] Installing Gems and dependencies...'
bundle install

echo '[*] Installing node_modules...'
yarn

echo '[*] Installing phantomjs-prebuilt...'
sudo yarn global add phantomjs-prebuilt

echo '[*] Installing bower...'
sudo yarn global add bower

echo '[*] Installing bower modules...'
bower install

echo '[*] Installing gulp...'
sudo yarn global add gulp

echo '[*] Migrating databases...'
rake db:migrate
rake db:migrate RAILS_ENV=test
