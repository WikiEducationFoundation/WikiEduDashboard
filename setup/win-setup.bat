echo OFF
echo Setting up your developmental environment. This may take a while.

echo [*] Installing chocolatey...
@"%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe" -NoProfile -InputFormat None -ExecutionPolicy Bypass -Command "iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))" && SET "PATH=%PATH%;%ALLUSERSPROFILE%\chocolatey\bin"

echo [*] Installing ruby...
choco install ruby2.devkit -y

echo [*] Installing Node.js...
choco install nodejs-lts -y

echo [*] Installing Gems...
call gem install bundler
call bundle install

echo [*] Installing Yarn...
choco install yarn -y

echo [*] Installing node modules...
call yarn

echo [*] Installing PhantomJs...
call yarn global add phantomjs-prebuilt

echo [*] Installing Pandoc...
choco install pandoc -y

echo [*] Creating configuration files...
copy config\application.example.yml config\application.yml
copy config\database.example.yml config\database.yml

echo [*] Installing XAMPP...
choco install bitnami-xampp -y
start C:\xampp\mysql\bin\mysqld

echo [*] Setting up database...
echo CREATE DATABASE dashboard DEFAULT CHARACTER SET utf8 DEFAULT COLLATE utf8_general_ci;CREATE DATABASE dashboard_testing DEFAULT CHARACTER SET utf8 DEFAULT COLLATE utf8_general_ci;exit| C:\xampp\mysql\bin\mysql -u root

echo [*] Installing Redis...
msiexec /i https://github.com/MicrosoftArchive/redis/releases/download/win-3.0.504/Redis-x64-3.0.504.msi

echo [*] Installing Gulp...
yarn global add gulp

echo [*] Installing R...
choco install r.project -y

echo [*] Migrating databases...
rake db:migrate
rake db:migrate RAILS_ENV=test
