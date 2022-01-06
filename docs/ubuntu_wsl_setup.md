1. Enable WSL and virtual machines (via "Turn Windows features on or off")
2. Install Ubuntu from Microsoft Store and make sure it's set for WSL 2
   1. Optional: install Windows Terminal

3. In Ubuntu terminal
   1. `sudo apt-add-repository -y ppa:rael-gc/rvm`
   2. `sudo apt-get update`
   3. `sudo apt-get install -y redis-server mariadb-server libmariadb-dev rvm nodejs npm pandoc`
   4. `sudo npm install --global yarn`
   5. `sudo service mysql start`
   6. Create mysql user `wiki` with password `wikiedu`:
      1. `sudo mysql`
      2. `CREATE USER 'wiki' IDENTIFIED BY 'wikiedu';`
      3. `GRANT ALL PRIVILEGES ON *.* TO 'wikiedu';`
      4. `exit;`
4. Close and reopen the Ubuntu terminal (to activate RVM)
5. In Ubuntu terminal:
   1. `rvm install 2.7.1`
   2. clone the WikiEduDashboard git repo and enter the directory
   3. `yarn`
   4. `yarn build`
   5. `bundle install`
   6. `bundle exec rake db:create`
   7. `bundle exec rake db:migrate`
   8. `rails s`

6. Now you should have it running at localhost:3000
