#!/usr/bin/env bash

clear

CLEAR_LINE='\r\033[K'
echo 'Setting up your developmental environment. This may take a while.'

printf '[*] Checking for Curl...'
if ! which curl >/dev/null; then
  printf "${CLEAR_LINE}Curl Not Found!\n"
  printf '[*] Installing Curl...'
  sudo apt-get install -y curl >/dev/null && printf "${CLEAR_LINE}[+] Curl installed!"
else
  printf "${CLEAR_LINE}Curl Found!\n"
fi

printf '[*] Adding keys...'

# Add keys for Yarn
curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | sudo apt-key add - > /dev/null && \
echo "deb https://dl.yarnpkg.com/debian/ stable main" | sudo tee /etc/apt/sources.list.d/yarn.list > /dev/null

# Add Keys for MariaDB
sudo apt-key adv --recv-keys --keyserver hkp://keyserver.ubuntu.com:80 0xF1656F24C74CD1D8 > /dev/null && \
sudo add-apt-repository 'deb [arch=amd64,i386,ppc64el] http://mirror.jmu.edu/pub/mariadb/repo/10.1/ubuntu xenial main' > /dev/null
printf "${CLEAR_LINE}[+] Added keys for required repositries!\n"

printf '[*] Updating Package lists...'
sudo apt-get update > /dev/null && printf "${CLEAR_LINE}[+] Updated Package lists!\n"

printf '[*] Installing R...'
sudo apt install -y r-base > /dev/null && printf "${CLEAR_LINE}[+] R installed!\n"

printf '[*] Installing node.js...'
if which node | grep node >/dev/null;then
  printf "${CLEAR_LINE}Node already installed!\n"
else
  curl -sL https://deb.nodesource.com/setup_8.x | sudo -E bash - && sudo apt-get install -y nodejs > /dev/null &&\
   printf "${CLEAR_LINE}[+] Node installed!\n"
fi

printf '[*] Installing GNUpg...'
sudo apt-get install -y gnupg > /dev/null && printf "${CLEAR_LINE}[+] GNUpg installed!\n"

printf '[*] Installing yarn...'
sudo apt-get install -y yarn > /dev/null && printf "${CLEAR_LINE}[+] Yarn installed!\n"

printf '[*] Installing pandoc...'
sudo apt-get install -y pandoc > /dev/null && printf "${CLEAR_LINE}[+] Pandoc installed!\n"

printf '[*] Installing redis-server...'
sudo apt install -y redis-server > /dev/null && printf "${CLEAR_LINE}[+] Redis-Server installed!\n"

printf '[*] Installing mariadbclient dependencies...'
sudo apt-get install -y libmariadbclient-dev > /dev/null && printf "${CLEAR_LINE}[+] Dependencies installed!\n"

printf '[*] Installing MariaDB-server...'
sudo apt-get install -y software-properties-common > /dev/null
sudo apt-get install -y mariadb-server > /dev/null && printf "${CLEAR_LINE}[+] MariaDB installed!"
sudo systemctl start mariadb.service > /dev/null && \
sudo systemctl enable mariadb.service > /dev/null && \
printf "${CLEAR_LINE}MariaDB service started!\n"

printf '[*] Checking for rvm...'
if ! which rvm > /dev/null; then
  gpg --keyserver hkp://keys.gnupg.net --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3 7D2BAF1CF37B13E2069D6956105BD0E739499BDB > /dev/null && printf "${CLEAR_LINE}[*] Installing rvm..." && \
  \curl -sSL https://get.rvm.io | bash -s stable > /dev/null && \
  printf "${CLEAR_LINE}[+] RVM installed!\n"
  source ~/.rvm/scripts/rvm
else
  printf "${CLEAR_LINE}RVM already installed!\n"
fi

printf '[*] Installing Ruby-2.5.0...'
rvm install ruby-2.5.0 > /dev/null && printf "${CLEAR_LINE}[+] Ruby-2.5.0 installed!\n"

printf '[*] Installing bundler...'
gem install bundler > /dev/null && printf "${CLEAR_LINE}[+] Bundler installed!\n"

printf '[*] Installing Gems and dependencies...'
bundle install > /dev/null && printf "${CLEAR_LINE}[+] Gems installed!\n"

printf '[*] Installing phantomjs-prebuilt...'
sudo yarn global add phantomjs-prebuilt > /dev/null && printf "${CLEAR_LINE}[+] phantomjs-prebuilt installed!\n"

printf '[*] Installing bower...'
sudo yarn global add bower > /dev/null && printf "${CLEAR_LINE}[+] bower installed!\n"

printf "[*] Creating Databases..."
echo "CREATE DATABASE dashboard DEFAULT CHARACTER SET utf8 DEFAULT COLLATE utf8_general_ci;
      CREATE DATABASE dashboard_testing DEFAULT CHARACTER SET utf8 DEFAULT COLLATE utf8_general_ci;
      exit" | sudo mysql -p && printf "${CLEAR_LINE}[+] Databases created!\n"

printf '[*] Checking for Database configurations...'
if [ -f config/database.yml ]; then
  printf "${CLEAR_LINE}Database configurations found!\n"
  echo 'You would need to connect the database for your configured user!'
  echo 'After connecting your database kindly run migrations with'
  echo '"rake db:migrate"'
  echo '"rake db:migrate RAILS_ENV=test"'
else
  printf "${CLEAR_LINE}Database configurations not found!\n"
  printf '[*] Creating Database configurations...'
  cp config/database.example.yml config/database.yml
  printf "${CLEAR_LINE}Database configurations created!\n"

  printf '[*] Creating User for Mysql...'
  echo "CREATE USER 'wiki'@'localhost' IDENTIFIED BY 'wikiedu';
      GRANT ALL PRIVILEGES ON dashboard . * TO 'wiki'@'localhost';
      GRANT ALL PRIVILEGES ON dashboard_testing . * TO 'wiki'@'localhost';
      exit" | sudo mysql -p > /dev/null && printf "${CLEAR_LINE}[+] User created!\n" && \
      printf '[*] Migrating databases...'
      rake db:migrate > /dev/null && \
      rake db:migrate RAILS_ENV=test > /dev/null && \
      printf "${CLEAR_LINE}[+] Database migration completed!\n"
fi

printf '[*] Checking for application configurations...'
if [ -f config/application.yml ]; then
  printf "${CLEAR_LINE}Application configurations found!\n"
else
  printf "${CLEAR_LINE}Application configurations not found!\n"
  printf '[*] Creating Application configurations...'
  cp config/application.example.yml config/application.yml && printf "${CLEAR_LINE}Application configurations created!\n"
fi

printf '[*] Installing node_modules...'
yarn > /dev/null && printf "${CLEAR_LINE}[+] node_modules installed!\n"

printf '[*] Installing bower modules...'
bower install > /dev/null && printf "${CLEAR_LINE}[+] bower modules installed!\n"

printf '[*] Installing gulp...'
sudo yarn global add gulp > /dev/null && printf "${CLEAR_LINE}[+] Gulp installed!\n"

echo 'Your developmental environment setup is completed! If you say any errors try to refer to the docs for manual installation or ask for help!'
