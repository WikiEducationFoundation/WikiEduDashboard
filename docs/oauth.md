[Back to README](../README.md)

## OAuth Setup

**If you have not already completed the [dashboard setup](setup.md) portion of the documentation, please head over there first.**

In order to use and develop the authenticated features of the application (course creation, the assignment design wizard, user management, etc) you will need to create a MediaWiki OAuth consumer).

[Log in to mediawiki](https://www.mediawiki.org/w/index.php?title=Special:UserLogin&returnto=Special%3AUserLogout&returntoquery=noreturnto%3D) with your username and password for mediawiki.org. Once you're logged in, click on "Preferences" in the upper right-hand corner. In the "User profile" tab under "Preferences" (selected by default), change the email address to your email. You'll need this to confirm your account and get your token and secret key in the next step.

You'll now [propose an OAuth consumer](https://www.mediawiki.org/wiki/Special:OAuthConsumerRegistration/propose). Fill out the form like so:

![Screenshot](https://lh3.googleusercontent.com/-BMSA42xP8fU/VbaP35rumaI/AAAAAAAAAAc/b40znxPGbkU/s1024-Ic42/Screen%252520Shot%2525202015-07-27%252520at%2525201.07.21%252520PM.png)

Clicking on the 'Propose consumer' button should return a token and secret, which you should store in your `application.yml` file.
