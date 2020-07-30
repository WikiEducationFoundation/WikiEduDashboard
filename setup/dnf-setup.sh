#!/usr/bin/env bash

clear
set -e
trap ErrorMessage ERR

. "$(dirname "$0")/color-helpers.sh"

ErrorMessage(){
  print_error "There was error while setting up your developmental environment!"
  print_error "Please check the log file in setup directory."
  echo "For manual instruction for setting up the developmental environment, refer to:"
  echo "https://github.com/WikiEducationFoundation/WikiEduDashboard/blob/master/docs/setup.md"
}

CLEAR_LINE='\r\033[K'

output_line()
{
  if [ -z ${2+x} ];then
    while read -r line
    do
      printf "${CLEAR_LINE}$line"
      echo $line &>> setup/log.txt
    done < <(eval $1)
  else
    while read -r line
    do
      printf "${CLEAR_LINE}$line"
    done < <(eval $1 | $2)
  fi
}

echo 'Setting up your developmental environment. This may take a while.'

echo '[+] Creating log file...'
touch setup/log.txt
print_success '[+] Log File created'

printf '[*] Checking for Ruby-2.7.1...\n'
if ruby -v | grep "ruby 2.7.1" >/dev/null; then
  printf "${CLEAR_LINE}Ruby already installed\n"
else
  print_error "Ruby-2.7.1 not found. Please install ruby-2.7.1 and run this script again."
  echo "One way to install ruby-2.7.1 is through RVM, Visit: https://rvm.io/"
  exit 0;
fi

printf '[*] Checking for Curl... \n'
if ! which curl >/dev/null; then
  print_error "${CLEAR_LINE}Curl Not Found\n"
  printf '[*] Installing Curl... \n'
  output_line "sudo dnf install -y curl" && print_success "${CLEAR_LINE}[+] Curl installed \n"
else
  printf "${CLEAR_LINE}Curl Found\n"
fi

printf '[*] Installing node.js... \n'
if which node >/dev/null;then
  printf "${CLEAR_LINE}Node already installed\n"
else
  output_line "sudo dnf install -y nodejs" && print_success "${CLEAR_LINE}[+] Node installed\n"
fi

printf '[*] Installing GNUpg... \n'
output_line "sudo dnf install -y gnupg" && print_success "${CLEAR_LINE}[+] GNUpg installed\n"

printf '[*] Installing yarn... \n'
if which yarn >/dev/null; then
  printf "${CLEAR_LINE}yarn already installed\n"
else
  curl --silent --location https://dl.yarnpkg.com/rpm/yarn.repo | sudo tee /etc/yum.repos.d/yarn.repo
  output_line "sudo dnf install -y yarn" && print_success "${CLEAR_LINE}[+] Yarn installed\n"
fi

printf '[*] Installing pandoc... \n'
if which pandoc >/dev/null; then
  printf "${CLEAR_LINE}pandoc already installed\n"
else
  output_line "sudo dnf install -y pandoc" && print_success "${CLEAR_LINE}[+] Pandoc installed\n"
fi

printf '[*] Installing redis-server... \n'
if which redis-server > /dev/null; then
  printf "${CLEAR_LINE}redis-server already installed\n"
else
  output_line "sudo dnf install -y redis" && print_success "${CLEAR_LINE}[+] Redis-Server installed\n"
fi

printf '[*] Installing MariaDB-server... \n'
if mysql -V | grep MariaDB > /dev/null; then
  printf "${CLEAR_LINE}MariaDB already installed\n"
else
  output_line "sudo dnf install -y mariadb-server" && print_success "${CLEAR_LINE}[+] MariaDB installed "
fi

printf '[*] Installing mariadbclient dependencies... \n'
output_line "sudo dnf install -y mariadb-devel" && print_success "${CLEAR_LINE}[+] Dependencies installed\n"

printf '[*] Installing bundler... \n'
if which bundler > /dev/null; then
  printf "${CLEAR_LINE}bundler already installed\n"
else
  output_line "gem install bundler" && print_success "${CLEAR_LINE}[+] Bundler installed\n"
fi

printf '[*] Updating bundler... \n'
if ruby should_update_rubygems.rb
  gem update --system
  printf '[+] Bundler updated\n'
else
  printf '[+] Bundler already up to date\n'
fi

printf '[*] Installing Gems... \n'
output_line "bundle install" && print_success "${CLEAR_LINE}[+] Gems installed\n"

printf '[*] Installing phantomjs-prebuilt... \n'
output_line "sudo yarn global add phantomjs-prebuilt" && print_success "${CLEAR_LINE}[+] phantomjs-prebuilt installed\n"

printf '[*] Checking for application configurations... \n'
if [ -f config/application.yml ]; then
  printf "${CLEAR_LINE}Application configurations found\n"
else
  printf "${CLEAR_LINE}Application configurations not found\n"
  printf '[*] Creating Application configurations... \n'
  cp config/application.example.yml config/application.yml && print_success "${CLEAR_LINE}Application configurations created\n"
fi

printf '[*] Starting MariaDB... \n'
sudo service mariadb start

printf "[*] Creating Databases... \n"
echo "CREATE DATABASE dashboard DEFAULT CHARACTER SET utf8 DEFAULT COLLATE utf8_general_ci;
      CREATE DATABASE dashboard_testing DEFAULT CHARACTER SET utf8 DEFAULT COLLATE utf8_general_ci;
      exit" | sudo mysql && print_success "${CLEAR_LINE}[+] Databases created\n"

printf '[*] Checking for Database configurations... \n'
if [ -f config/database.yml ]; then
  printf "${CLEAR_LINE}Database configurations found\n"
  echo 'You would need to connect the database for your configured user '
  echo 'After connecting your database kindly run migrations with'
  echo '"rake db:migrate"'
  echo '"rake db:migrate RAILS_ENV=test"'
else
  printf "${CLEAR_LINE}Database configurations not found\n"
  printf '[*] Creating Database configurations... \n'
  cp config/database.example.yml config/database.yml
  print_success "${CLEAR_LINE}Database configurations created\n"

  printf '[*] Creating User for Mysql... \n'
  echo "CREATE USER 'wiki'@'localhost' IDENTIFIED BY 'wikiedu';
      GRANT ALL PRIVILEGES ON dashboard . * TO 'wiki'@'localhost';
      GRANT ALL PRIVILEGES ON dashboard_testing . * TO 'wiki'@'localhost';
      exit" | sudo mysql > /dev/null && print_success "${CLEAR_LINE}[+] User created\n"
fi

printf '[*] Migrating databases... \n'
output_line "rake db:migrate" && \
output_line "rake db:migrate RAILS_ENV=test"  && \
print_success "${CLEAR_LINE}[+] Database migration completed\n"

printf '[*] Installing node_modules... \n'
output_line "yarn" && print_success "${CLEAR_LINE}[+] node_modules installed\n"

echo 'Your developmental environment setup is completed  If you have any errors try to refer to the docs for manual installation or ask for help '
