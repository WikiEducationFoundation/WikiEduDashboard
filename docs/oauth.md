[Back to README](../README.md)

## OAuth Setup

**If you have not already completed the [dashboard setup](setup.md) portion of the documentation, please head over there first.**

In order to use and develop the authenticated features of the application (course creation, the assignment design wizard, user management, etc) you will need to create a MediaWiki OAuth consumer. You can skip this setup process and use the consumer provided in `config/application.example.yml` to get started; this consumer cannot be used to make edits or update preferences on Wikipedia, but can be used to log in.

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

#### Updating the production consumer
When you request a new consumer, add the tokens to the production server's `application.yml`, commented out, so they are ready for the switchover.

0. Ideally, schedule the consumer update for a time when few users will be active.
1. Add a site notice informing users that they will be logged out, 30 mintues or more before the consumer is updated.
2. Initiate a snapshot of the Linode server and wait for it to finish (just in case).
3. Update `application.yml`, commenting out the old tokens and uncommenting the new, and removing the sitenotice.
4. In a rails console on production, remove all oauth tokens from users: `User.update_all(wiki_token: nil, wiki_secret: nil)`.
5. Restart both the main server process (`touch tmp/restart.txt`) and the sidekiq processes (`cap production deploy:sidekiq:restart`).
6. Once an edit has been made with the new consumer, find the CID of that consumer via `Special:Tags` on Wikipedia, and add it to the list of CIDs in `application.yml`.
7. Restart the server and sidekiq processes again.

## Admin permissions

Give users admin privileges in the app, e.g. to approve submitted courses, by setting the users.permissions field to "1".  For example, if your wiki username is "RageSock",
```
rails runner "User.find_by(wiki_id: 'RageSock').update(permissions: User::Permissions::ADMIN)"
```
or via mysql,
```
mysql -e "update users set permissions = 1 where wiki_id='RageSock'" dashboard
```
