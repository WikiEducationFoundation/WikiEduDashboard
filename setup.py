#!/usr/bin/env python3
import platform,subprocess

def deb_setup():
  print ("Your system is found to be debian-based.")
  subprocess.run("sudo chmod 775 setup/deb-setup.sh && setup/deb-setup.sh",shell=True,check=True)

def win_setup():
  print ("Your system is found to be Windows")
  subprocess.run("runas /user:Administrator \"setup\win-setup.bat\"",shell=True,check=True)

def osx_setup():
  print ("Your system is found to be OSX")
  subprocess.run("sudo chmod 775 setup/deb-setup.sh && setup/deb-setup.sh",shell=True,check=True)

if platform.platform().lower().find('ubuntu') != -1 or platform.platform.lower().find('debian') != -1:
  deb_setup()
elif platform.platform().lower().find('osx') != -1:
  osx_setup()
elif platform.platform().lower().find('windows') != -1:
  win_setup()
else:
  print ("Sorry! Your operating is not supported by this script. Please refer https://github.com/WikiEducationFoundation/WikiEduDashboard/blob/master/docs/setup.md for manual setup instructions.")
