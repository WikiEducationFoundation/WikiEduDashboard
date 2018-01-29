#!/bin/bash

echo 'Setting up your developmental environment. This may take a while.'

echo '[*] Checking for Curl...'
if ! which curl >/dev/null; then
  echo 'Curl Not Found!'
  echo '[*] Installing Curl...'
  sudo apt-get install curl >/dev/null && echo '[+] Curl installed!'
else
  echo 'Curl Found!'
fi

echo '[*] Adding keys...'

# Add keys for Yarn
curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | sudo apt-key add - > /dev/null && \
echo "deb https://dl.yarnpkg.com/debian/ stable main" | sudo tee /etc/apt/sources.list.d/yarn.list > /dev/null

# Add Keys for MariaDB
sudo apt-key adv --recv-keys --keyserver hkp://keyserver.ubuntu.com:80 0xF1656F24C74CD1D8 > /dev/null && \
sudo add-apt-repository 'deb [arch=amd64,i386,ppc64el] http://mirror.jmu.edu/pub/mariadb/repo/10.1/ubuntu xenial main' > /dev/null
echo '[+] Added keys for required repositries!'

echo '[*] Updating Package lists...'
sudo apt-get update > /dev/null && echo '[+] Updated Package lists!'

echo '[*] Installing R...'
sudo apt install r-base > /dev/null && echo '[+] R installed!'

echo '[*] Install node.js...'
if which node | grep node >/dev/null;then
  echo 'Node already installed!'
else
  curl -sL https://deb.nodesource.com/setup_8.x | sudo -E bash - && sudo apt-get install -y nodejs > /dev/null &&\
   echo '[+] Node installed!'
fi

echo '[*] Installing GNUpg...'
sudo apt-get install gnupg > /dev/null && echo '[+] GNUpg installed!'

echo '[*] Installing yarn...'
sudo apt-get install yarn > /dev/null && echo '[+] Yarn installed!'

echo '[*] Installing pandoc...'
sudo apt-get install pandoc > /dev/null && echo '[+] Pandoc installed!'

echo '[*] Installing redis-server...'
sudo apt install redis-server > /dev/null && '[+] Redis-Server installed!'

echo '[*] Installing mariadbclient dependencies...'
sudo apt-get install libmariadbclient-dev > /dev/null && echo '[+] Dependencies installed!'

echo '[*] Installing MariaDB-server...'
echo 'Please Setup your Root password when asked during installation!'
sudo apt-get install software-properties-common > /dev/null
sudo apt-get install -y mariadb-server > /dev/null && echo '[+] MariaDB installed!'
sudo systemctl start mariadb.service > /dev/null && \
sudo systemctl enable mariadb.service > /dev/null && \
echo 'MariaDB service started!'

echo '[*] Checking for rvm...'
if ! which rvm > /dev/null; then
  gpg --keyserver hkp://keys.gnupg.net --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3 7D2BAF1CF37B13E2069D6956105BD0E739499BDB && echo '[*] Installing rvm...' &&\
   \curl -sSL https://get.rvm.io | bash -s stable > /dev/null &&\
    echo '[+] RVM installed!'
  source /home/sage/.rvm/scripts/rvm > /dev/null
fi

echo '[*] Installing Ruby-2.5.0...'
rvm install ruby-2.5.0 > /dev/null && echo '[+] Ruby-2.5.0 installed!'

echo '[*] Installing bundler...'
gem install bundler > /dev/null && echo '[+] Bundler installed!'

echo '[*] Installing Gems and dependencies...'
bundle install > /dev/null && echo '[+] Gems installed!'

echo '[*] Installing phantomjs-prebuilt...'
sudo yarn global add phantomjs-prebuilt > /dev/null && echo '[+] phantomjs-prebuilt installed!'

echo '[*] Installing bower...'
sudo yarn global add bower > /dev/null && echo '[+] bower installed!'

echo "[*] Creating Databases..."
echo 'Enter password for Mysql root user'
echo "CREATE DATABASE dashboard DEFAULT CHARACTER SET utf8 DEFAULT COLLATE utf8_general_ci;
      CREATE DATABASE dashboard_testing DEFAULT CHARACTER SET utf8 DEFAULT COLLATE utf8_general_ci;
      exit" | sudo mysql -p

echo '[*] Checking for Database configurations...'
if [ -f config/database.yml ]; then
  echo 'Database configurations found!'
  echo 'You would need to connect the database for your configured user!'
  echo 'After connecting your database kindly run migrations with'
  echo '"rake db:migrate"'
  echo '"rake db:migrate RAILS_ENV=test"'
else
  echo 'Database configurations not found!'
  echo '[*] Creating Database configurations...'
  cp config/database.example.yml config/database.yml

  echo '[*] Creating User for Mysql...'
  echo "CREATE USER 'wiki'@'localhost' IDENTIFIED BY 'wikiedu';
      GRANT ALL PRIVILEGES ON dashboard . * TO 'wiki'@'localhost';
      GRANT ALL PRIVILEGES ON dashboard_testing . * TO 'wiki'@'localhost';
      exit" | sudo mysql -p > /dev/null && echo '[+] User created!' && \
      echo '[*] Migrating databases...'
      rake db:migrate > /dev/null && \
      rake db:migrate RAILS_ENV=test > /dev/null && \
      echo '[+] Database migration completed!'
fi

echo '[*] Checking for application configurations...'
if [ -f config/application.yml ]; then
  echo 'Application configurations found.'
else
  echo 'Application configurations not found!'
  echo '[*] Creating Application configurations...'
  cp config/application.example.yml config/application.yml
fi

echo '[*] Installing node_modules...'
yarn > /dev/null && echo '[+] node_modules installed!'

echo '[*] Installing bower modules...'
bower install > /dev/null && echo '[+] bower modules installed!'

echo '[*] Installing gulp...'
sudo yarn global add gulp > /dev/null && echo '[+] Gulp installed!'

echo 'Your developmental environment setup is completed! If you say any errors try to refer to the docs for manual installation or ask for help!'
