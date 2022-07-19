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
      3. `GRANT ALL PRIVILEGES ON *.* TO 'wiki';`
      4. `exit;`
4. Close and reopen the Ubuntu terminal (to activate RVM)
5. In Ubuntu terminal:
   1. `sudo usermod -a -G rvm $USER` where $User is your UNIX username (preferably restart your machine after this step)
   2. `rvm install 3.1.2`
   3.  Clone the WikiEduDashboard git repo and enter the directory
   4.  In config folder:
       1. Either save `application.example.yml` and `database.example.yml` as `application.yml` and `database.yml`, respectively, or 
       2. Copy `application.example.yml` to `application.yml` and `database.example.yml` to `database.yml` using cp command.
   5. `bundle install`
   6. `yarn`
   7. `yarn build`
   8. `bundle exec rake db:create`
   9. `bundle exec rake db:migrate`
   10. `rails s`

6. Now you should have it running at localhost:3000
