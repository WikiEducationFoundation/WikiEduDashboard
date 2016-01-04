[Back to README](../README.md)

## OAuth Setup

**If you have not already completed the [dashboard setup](setup.md) portion of the documentation, please head over there first.**

In order to use and develop the authenticated features of the application (course creation, the assignment design wizard, user management, etc) you will need to create a MediaWiki OAuth consumer).

[Log in to a Wikimedia site](https://www.mediawiki.org/w/index.php?title=Special:UserLogin&returnto=Special%3AUserLogout&returntoquery=noreturnto%3D) with your username and password. Once you're logged in, click on "Preferences" in the upper right-hand corner. In the "User profile" tab under "Preferences" (selected by default), set your email address if you haven't already. You'll need this to confirm your account and get your token and secret key in the next step.

To register an OAuth consumer, your account must be "confirmed". This happens automatically after a certain number of edits, but if your account is new, you can request your account to be manually confirmed (here)[https://meta.wikimedia.org/wiki/Steward_requests/Permissions#Using_this_page]. 

You'll now [propose an OAuth consumer](https://meta.wikimedia.org/wiki/Special:OAuthConsumerRegistration/propose). Fill out the form with the following values:

- **Application name:** `<YOUR_NAME>_at_<YOUR_COMPANY>`
- **Application description:** `<YOUR_NAME>'s local machine`
- **OAuth "callback" URL:** `http://localhost:3000/users/auth/mediawiki/callback`
- **Contact email address:** `<YOUR_EMAIL>` (this must match your Wiki account email)
- **Permissions:** select `Edit existing pages` and `Create, edit, and move pages`

<!--![Screenshot](https://lh3.googleusercontent.com/-BMSA42xP8fU/VbaP35rumaI/AAAAAAAAAAc/b40znxPGbkU/s1024-Ic42/Screen%252520Shot%2525202015-07-27%252520at%2525201.07.21%252520PM.png)-->

Clicking on the 'Propose consumer' button should return a token and secret, which you should store in your `application.yml` file.
