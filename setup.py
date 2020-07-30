#!/usr/bin/env python3
import platform
import subprocess

print ("WARNING! This is a work in progress script. It has been tested to work for Fedora and debian-based systems. \
  There are individual operating system dependent scripts being called from this one. \
  You can find them in setup directory. The script for windows is still not complete. \
  You can use them as a starting point or as a reference. If you run into any errors while running this script, \
  please comment with your issue on https://github.com/WikiEducationFoundation/WikiEduDashboard/issues/1709 \
  Please upload your logs for installation with your issue reports. \
  The logs can be found in the setup directory. If you can help improve this script, \
  We would love your contributions.")

print ("Please install ruby-2.7.1 before running this script.")

def deb_setup():
    print ("Your system is found to be debian-based.")
    subprocess.run("sudo chmod 775 setup/deb-setup.sh && setup/deb-setup.sh",
                   shell=True, check=True)


def dnf_setup():
    print("Your system is found to be Fedora")
    subprocess.run("sudo chmod 775 setup/dnf-setup.sh && setup/dnf-setup.sh",
                   shell=True, check=True)


def win_setup():
    print ("Your system is found to be Windows")
    subprocess.run("runas /user:Administrator \"setup\win-setup.bat\"",
                   shell=True, check=True)


def osx_setup():
    print ("Your system is found to be OSX")
    subprocess.run("sudo chmod 775 setup/macOS-setup.sh && setup/macOS-setup.sh",
                   shell=True, check=True)

if platform.platform().lower().find('ubuntu') != -1 \
        or platform.platform().lower().find('debian') != -1 \
        or platform.platform().lower().find('elementary') != -1:
    deb_setup()
elif platform.platform().lower().find('fedora') != -1:
    dnf_setup()
elif platform.platform().lower().find('darwin') != -1 \
        or platform.platform().lower().find('mac') != -1: 
    osx_setup()
elif platform.platform().lower().find('windows') != -1:
    win_setup()
else:
    print ("Sorry! Your operating is not supported by this script. Please refer \
https://github.com/WikiEducationFoundation/WikiEduDashboard/blob/master/ \
docs/setup.md for manual setup instructions.")
