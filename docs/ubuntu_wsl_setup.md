1. Enable WSL and virtual machines (via "Turn Windows features on or off")
   1. Open "Turn Windows features on or off" from the control panel
   2. Select "Windows Subsystem for Linux" and "Virtual Machine Platform"
   3. Windows will prompt you to restart your system to enable these.
2. Install "Ubuntu" app
   1. Open "Microsoft Store", search for and install the app "Ubuntu"
   2. Optional: install Windows Terminal from the Microsoft Store as well
   3. Check whether you are on WSL 2: open a Windows terminal and enter ``. If your system is on WSL 1, try the upgrade command `wsl --set-version Ubuntu 2`. You may need to take additional steps to enable WSL 2, such as installing a kernel upgrade and enabling virtualization in your BIOS. See https://learn.microsoft.com/en-us/windows/wsl/install
3. Launch the Ubuntu app, which opens an Ubuntu terminal, and then:
   1. Create your Ubuntu username and password (if this is the first time using the Ubuntu system)
   2. Add the RVM repo so you can install Ruby: `sudo apt-add-repository -y ppa:rael-gc/rvm`
   3. Install RVM: `sudo apt install rvm`
   4. Add your user to the rvm group: `sudo usermod -a -G rvm [your username]`
   5. Close and reopen the Ubuntu terminal to activate RVM
4. Get the Dashboard code and install Ruby and other prerequisites.
   1. If you haven't done so already, fork this repo on Github
   2. From Ubuntu terminal, clone your forked repo by replacing the URL in this command: `git clone https://WikiEducationFoundation/WikiEduDashboard.git`. For performance, it's important to install this in the WSL filesystem.
   3. Enter the Dashboard directory, then attempt to install the Dashboard's current Ruby version (updating the version number in this command if necessary): `rvm install 3.1.2`.
   5. `sudo apt-get update`
   6. `sudo apt-get install -y mariadb-server libmariadb-dev`
   7. Start the database: `sudo /etc/init.d/mariadb start`
5. The rest of the installation process should work the same way as a normal Linux installation, and the setup script can automate most of it: `python3 setup.py`. If the setup script fails, refer to the manual setup procedures in `setup.md` to continue.
6. Build the assets: `yarn build`
7. Run `rails s`. Now you should have a development running and accessible via web browser at localhost:3000.

For troubleshooting, look at the end of the document: [Troubleshooting](./troubleshooting.md)

If this doesn't work smoothly, please let the maintainers know about what went wrong (and what you did to work around the problem, if you found one).
