[Back to README](../README.md)

## Installing Ruby

### on Mac OS
- You'll likely need `homebrew` before you can install Ruby.
- Both `rvm` and `rbenv` are good ways to install Ruby.
- If you run into errors during Ruby installation, run `brew doctor` and follow the advice given, if any.

### on Windows
- It's highly recommended to use WSL2 for your development environment. Verify that you have version 2 enabled. `rvm` or `rbenv` should work from there.

### on Linux
- Use `rvm` or `rbenv`.


## Other common setup issues

- **Most integration tests fail with an exception.** This is usually caused by an improperly installed/linked version of QT, particularly on OSX. [This wiki section](https://github.com/thoughtbot/capybara-webkit/wiki/Installing-Qt-and-compiling-capybara-webkit#video-playback-mp4-on-osx-requires-qt-5) should set you straight.

- **"Error: EACCES: permission denied, open '/home/username/.babel.json'"** This happen, when babel don't have acces to ~/. To fix this, use command: `BABEL_DISABLE_CACHE=1 yarn start`

- **"sh: 1: node: not found"** This usually happen on Ubuntu 16.04, when nodejs is not linked as 'node'. To fix this, use command: `sudo ln -s /usr/bin/nodejs /usr/bin/node`

- **"Gem::Ext::BuildError: ERROR: Failed to build gem native extension. *.rb can't find header files on running `bundle install`"** This happens when header files required are not installed in the system. To fix this install a package, using command:  `sudo apt-get install ruby2.3-dev`

- **My sql setup should come before installing bundler.**

- **"Sorry you can't use Pry without Readline or a compatible library". add  `rb-readline`** to the Gemfile in the development group.

- **For Debian users, if you could not start the mysql command line using**`sudo mysql`. Your default password is blank. Go to database.yml and type in your password in the password field.
    - In database.yml: `password: "mypassword"`
Then start the command line:
    - Debian: `mysql -u root -p`
    - `SET PASSWORD FOR 'root'@'localhost' = PASSWORD('mypassword')`
    - `CREATE DATABASE dashboard DEFAULT CHARACTER SET utf8 DEFAULT COLLATE utf8_general_ci;`
    - `CREATE DATABASE dashboard_testing DEFAULT CHARACTER SET utf8 DEFAULT COLLATE utf8_general_ci;`
    - `exit`


- **When running yarn : ** `ERROR: There are no scenarios; must have at least one`.
Your system has cmdtest installed, which provides a different program as yarn. Uninstall it `sudo apt remove cmdtest`, then re-install yarn `sudo npg -g install yarn` and try again.

- **To check if redis is running as a daemon in Linux** `ps aux | grep redis-server`

- Use node v10 or lower to avoid any errors.
- **For WSL users , if rspec tests are taking too long to run** make sure to fork the repo in the linux file system and not in the windows partition. Use command `pwd` to know the exact path of your repo. If the path starts with `/mnt/`, the repo is in windows partition. Follow the documentation availible at link: https://learn.microsoft.com/en-us/windows/wsl/filesystems to know more about storing and moving files in the linux file system. 

If you have received error related to dependencies(`sudo apt-get install -y redis-server mariadb-server libmariadb-dev rvm nodejs npm pandoc`), try to install packages one by one and figure out which packages are creating problems)
Solution to some of the errors for WSL users:
1. mariaDB Package error: (`The following packages have unmet dependencies: mariadb-server : Depends: mariadb-server-10.4 (>= 1:10.4.8+maria~disco) but it is not going to be installed`)
   	Try `sudo aptitude install mariadb-server`: you will get suggestions of the packages not installed. When prompted for accepting the solution - write 'n', then it will fix itself and will again prompt for reinstalling mariadb packages - this time write 'y'. Reopen the terminal and check if you can start mariadb server
2. npm error:(`unmet dependencies`) 
   	Try using `aptitude`.
   	`sudo apt-get install aptitude`
   	`sudo aptitude install npm`
3. rvm install 3.1.2' command error: (`cannot create directory...: Permission denied`)
   	Try using `rvm fix-permissions system; rvm fix-permissions user`
4. error: `usermod: group 'rvm' does not exist:` try `sudo groupadd rvm`
