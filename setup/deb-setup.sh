#!/bin/bash

echo 'Setting up your developmental environment. This may take a while.'

echo '[*] Adding keys...'
curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | sudo apt-key add -
echo "deb https://dl.yarnpkg.com/debian/ stable main" | sudo tee /etc/apt/sources.list.d/yarn.list
sudo apt-get update

echo '[*] Installing GNUpg...'
sudo apt-get install gnupg

echo '[*] Adding Keys for rvm...'
gpg --keyserver hkp://keys.gnupg.net --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3 7D2BAF1CF37B13E2069D6956105BD0E739499BDB && echo '[*] Installing rvm...' && \curl -sSL https://get.rvm.io | bash -s stable

echo '[*] Installing Ruby-2.5.0...'
sudo rvm install ruby-2.5.0

echo '[*] Install node.js...'
curl -sL https://deb.nodesource.com/setup_8.x | sudo -E bash -
sudo apt-get install -y nodejs

echo '[*] Installing bundler...'
gem install bundler

echo '[*] Installing Gems and dependencies...'
sudo apt-get install libmysqlclient-dev libpq-dev libqtwebkit-dev
bundle install

echo '[*] Installing yarn...'
sudo apt-get install yarn

echo '[*] Installing node_modules...'
yarn

echo '[*] Installing phantomjs-prebuilt...'
sudo yarn global add phantomjs-prebuilt

echo '[*] Installing bower...'
sudo yarn global add bower

echo '[*] Installing bower modules...'
bower install

echo '[*] Installing pandoc...'
sudo apt-get install pandoc

echo '[*] Creating configuration files...'
cd config
cp application.example.yml application.yml
cp database.example.yml database.yml
cd ..

echo '[*] Installing Mysql-server...'
sudo apt-get install mysql-server

echo '[*] Creating databases...'
echo 'Enter password for Mysql root user'
echo 'CREATE DATABASE dashboard DEFAULT CHARACTER SET utf8 DEFAULT COLLATE utf8_general_ci;
      CREATE DATABASE dashboard_testing DEFAULT CHARACTER SET utf8 DEFAULT COLLATE utf8_general_ci;
      exit' | sudo mysql -p

echo '[*] Installing redis-server...'
sudo apt install redis-server

echo '[*] Installing gulp...'
sudo yarn global add gulp

echo '[*] Installing R...'
sudo apt install r-base

echo '[*] Migrating databases...'
rake db:migrate
rake db:migrate RAILS_ENV=test
