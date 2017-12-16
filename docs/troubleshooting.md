[Back to README](../README.md)

## Common setup issues

- **Most integration tests fail with an exception.** This is usually caused by an improperly installed/linked version of QT, particularly on OSX. [This wiki section](https://github.com/thoughtbot/capybara-webkit/wiki/Installing-Qt-and-compiling-capybara-webkit#video-playback-mp4-on-osx-requires-qt-5) should set you straight.

- **"Error: EACCES: permission denied, open '/home/username/.babel.json'"** This happen, when babel don't have acces to ~/. To fix this, use command: `BABEL_DISABLE_CACHE=1 gulp`

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

- **Make sure that the CLI
gulp version is same as the Local version** `gulp -v`.
