echo OFF
echo Setting up your developmental environment. This may take a while.

echo [*] Installing chocolatey...
@"%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe" -NoProfile -InputFormat None -ExecutionPolicy Bypass -Command "iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))" && SET "PATH=%PATH%;%ALLUSERSPROFILE%\chocolatey\bin"
echo [+] Chco installed!

echo [*] Installing Node.js...
choco install nodejs-lts -y
echo [+] Node.js installed!

echo [*] Installing Gems...
@echo off
call gem install bundler
call gem update --system
call gem install mysql2 -v 0.5.4 --platform=ruby -- --with-mysql-lib="C:\xampp\mysql\lib" --withmysql-include="C:\xampp\mysql\include"'
setx PATH "%PATH%;C:\xampp" /M
call bundle install
echo [+] Gems installed!

echo [*] Installing Yarn...
choco install yarn -y
SET "PATH=%PATH%;%ProgramFiles(x86)%\Yarn\bin"
echo [+] Yarn installed!

echo [*] Installing node modules...
call yarn
echo [+] Node modules installed!

echo [*] Installing Pandoc...
choco install pandoc -y
echo [+] Pandoc installed!

echo [*] Creating configuration files...
copy config\application.example.yml config\application.yml
copy config\database.example.yml config\database.yml
echo [+] Configuration files created!

echo [*] Installing XAMPP...
choco install bitnami-xampp -y
echo [+] XAMPP install complete!
@echo off

echo [*] Creating databases...
echo CREATE DATABASE IF NOT EXISTS dashboard DEFAULT CHARACTER SET utf8 DEFAULT COLLATE utf8_general_ci; > setup.sql
echo CREATE DATABASE IF NOT EXISTS dashboard_testing DEFAULT CHARACTER SET utf8 DEFAULT COLLATE utf8_general_ci; >> setup.sql
"C:\xampp\mysql\bin\mysql.exe" -u root < setup.sql
del setup.sql

echo [+] Databases created!


@echo off

echo [*] Creating user for MySQL...
echo GRANT ALL PRIVILEGES ON dashboard.* TO 'wiki'@'localhost'; >> setup.sql
echo GRANT ALL PRIVILEGES ON dashboard_testing.* TO 'wiki'@'localhost'; >> setup.sql
"C:\xampp\mysql\bin\mysql.exe" -u root < setup.sql
del setup.sql
echo [+] Database user created!


echo [*] Installing Redis...
msiexec /i https://github.com/MicrosoftArchive/redis/releases/download/win-3.0.504/Redis-x64-3.0.504.msi
echo [+] Redis installed!

SET "PATH=%PATH%;%LOCALAPPDATA%\Yarn\bin"

echo [*] Migrating databases...
call rails db:migrate
call rails db:migrate RAILS_ENV=test
echo [+] Database migration complete!

echo Your developmental environment setup is complete. If you there are any errors, please refer to the docs for manual installation, or ask for help.
