#!/bin/bash

echo 'Setting up your developmental environment. This may take a while.'

echo '[*] Installing GNUpg...'
brew install gnupg

echo '[*] Adding Keys for rvm...'
gpg --keyserver hkp://keys.gnupg.net --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3 7D2BAF1CF37B13E2069D6956105BD0E739499BDB

echo '[*] Installing rvm...'
\curl -sSL https://get.rvm.io | bash -s stable

echo '[*] Installing Ruby-2.5.0...'
sudo rvm install ruby-2.5.0

echo '[*] Install node.js...'
brew install node

echo '[*] Installing bundler...'
gem install bundler

echo '[*] Installing Gems and dependencies...'
bundle install

echo '[*] Installing yarn...'
brew install yarn

echo '[*] Installing node_modules...'
yarn

echo '[*] Installing phantomjs-prebuilt...'
sudo yarn global add phantomjs-prebuilt

echo '[*] Installing bower...'
sudo yarn global add bower

echo '[*] Installing bower modules...'
bower install

echo '[*] Installing pandoc...'
brew install pandoc

echo '[*] Creating configuration files...'
cd config
cp application.example.yml application.yml
cp database.example.yml database.yml
cd ..

echo '[*] Installing Mysql-server...'
brew install mysql
mysql.server start

echo '[*] Creating databases...'
echo 'Enter password for Mysql root user'
echo 'CREATE DATABASE dashboard DEFAULT CHARACTER SET utf8 DEFAULT COLLATE utf8_general_ci;
      CREATE DATABASE dashboard_testing DEFAULT CHARACTER SET utf8 DEFAULT COLLATE utf8_general_ci;
      exit' | sudo mysql -p

echo '[*] Installing redis-server...'
brew install redis

echo '[*] Installing gulp...'
sudo yarn global add gulp

echo '[*] Installing R...'
brew tap homebrew/science && brew install r

echo '[*] Migrating databases...'
rake db:migrate
rake db:migrate RAILS_ENV=test
