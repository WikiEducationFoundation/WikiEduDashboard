# Ubuntu WSL Setup Guide

This docs simply explain how Windows users can set up their environment using WSL

1. Enable WSL and virtual machines (via "Turn Windows features on or off")
    (a) Open "Turn Windows features on or off" from the control panel
    (b) Select "Windows Subsystem for Linux" and "Virtual Machine Platform"
    (c) Windows will prompt you to restart your system to enable these.

2. Install "Ubuntu" app
     (a) install ubuntu here: <https://apps.microsoft.com/detail/9pdxgncfsczv?hl=en-us&gl=US>
     (b) install windows terminal here (optional): <https://apps.microsoft.com/detail/9n0dx20hk701?hl=en-us&gl=US>
     (b) if you encounter any problem in step (a) and (b) visit here <https://learn.microsoft.com/en-us/windows/wsl/install> for more guides

3. Launch the Ubuntu app, which opens an Ubuntu terminal, and then:
      (a) Create Your Ubuntu username and password (if this is the first time using the Ubuntu system)
      (b) copy and paste this: "sudo apt-add-repository -y ppa:rael-gc/rvm" to create RVM repo
      (c) copy and paste this: "sudo apt install rvm" to install RVM
      (d) "sudo usermod -a -G rvm [your username]" copy and paste this to add your user to the rvm group
      (e) Close and reopen the Ubuntu terminal to activate RVM

4. Get the Dashboard code and install Ruby and other prerequisites.
     (a) fork WikiEduDashBoard repo here: <https://docs.github.com/en/pull-requests/collaborating-with-pull-requests/working-with-forks/fork-a-repo> if you have not done so.
     (b) From Ubuntu terminal,  clone your forked repo by replacing the URL in this command: `git clone https://github.com/{your-github-username}/WikiEducationFoundation/WikiEduDashboard.git`
     (d) Enter the Dashboard directory, then attempt to install the Dashboard's current Ruby version (updating the version number in this command if necessary): `rvm install 3.2.9`.
     (e) Update system packages: `sudo apt-get update`
     (f) Install MariaDB: `sudo apt-get install -y mariadb-server libmariadb-dev`
     (g) Start the database: `sudo /etc/init.d/mariadb start`

5. Run setup script: `python3 setup.py`. If it fails, refer to the manual setup procedures in [`setup.md`](./setup.md) to continue.

6. Build the assets: `yarn build`

7. Run `rails s`. Now you should have a development running and accessible via web browser at localhost:3000.

For troubleshooting, look at the end of the document: [Troubleshooting](./troubleshooting.md)

If this doesn't work smoothly, please let the maintainers know about what went wrong (and what you did to work around the problem, if you found one).
