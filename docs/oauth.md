[Back to README](../README.md)

## OAuth Setup

**If you have not already completed the [dashboard setup](setup.md) portion of the documentation, please head over there first.**

In order to use and develop the authenticated features of the application (course creation, the assignment design wizard, user management, etc) you will need to create a MediaWiki OAuth consumer.

If you haven't already set an email address for your Wikimedia project account, [log in to a Wikimedia site](https://www.mediawiki.org/w/index.php?title=Special:UserLogin&returnto=Special%3AUserLogout&returntoquery=noreturnto%3D) with your username and password. Once you're logged in, click on "Preferences" in the upper right-hand corner. In the "User profile" tab under "Preferences" (selected by default), set your email address. You'll need this to confirm your account and get your token and secret key in the next step.

To register an OAuth consumer, your account must be "confirmed". This happens automatically after a certain number of edits, but if your account is new and you're impatient, you can request your account to be manually confirmed [here](https://meta.wikimedia.org/wiki/Steward_requests/Permissions#Using_this_page).

You'll now [propose an OAuth consumer](https://meta.wikimedia.org/wiki/Special:OAuthConsumerRegistration/propose). Fill out the form with the following values:

- **Application name:** `<YOUR_NAME>_at_<YOUR_COMPANY>`
- **Application description:** `<YOUR_NAME>'s local machine`
- **OAuth "callback" URL:** `http://localhost:3000/users/auth/mediawiki/callback`
- **Contact email address:** `<YOUR_EMAIL>` (this must match your Wikimedia account email)
- **Permissions:** select `Edit existing pages` and `Create, edit, and move pages`
- **Public RSA Key:** Leave this blank, so that you receive a secret key in the next step.

<!--![Screenshot](https://lh3.googleusercontent.com/-BMSA42xP8fU/VbaP35rumaI/AAAAAAAAAAc/b40znxPGbkU/s1024-Ic42/Screen%252520Shot%2525202015-07-27%252520at%2525201.07.21%252520PM.png)-->

Clicking on the 'Propose consumer' button should return a token and secret, which you should store in your `application.yml` file.

### Production and other consumers

A development consumer, used only by the proposer, will work immediately. For production or shared testing environments, consumers must be approved before anyone but the proposer can authorize the application. You can [post a request for approval here](https://meta.wikimedia.org/wiki/Steward_requests/Miscellaneous) ([see example](https://meta.wikimedia.org/w/index.php?title=Steward_requests/Miscellaneous&diff=prev&oldid=15398770)).

## Admin permissions

Give users admin privileges in the app, e.g. to approve submitted courses, by setting the users.permissions field to "1".  For example, if your wiki username is "RageSock",
```
rails runner "User.find_by(wiki_id: 'RageSock').update_attributes(permissions: User::Permissions::ADMIN)"
```
or via mysql,
```
mysql -e "update users set permissions = 1 where wiki_id='RageSock'" dashboard
```
