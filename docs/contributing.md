[Back to README](../README.md)

## Contributing

#### Developer Resources

- [MediaWiki API Manual](https://www.mediawiki.org/wiki/Manual:Contents)
- [MediaWiki API Sandbox](https://en.wikipedia.org/wiki/Special%3aApiSandbox)
- [Quarry](http://quarry.wmflabs.org/): Public querying interface for the Labs replica database. Very useful for testing SQL queries and for figuring out what data is available.
- [Guide to the front end](frontend.md)

#### Code Style
This project adheres as strictly as possible to the community [Ruby Style Guide](https://github.com/bbatsov/ruby-style-guide). [Rubocop](https://github.com/bbatsov/rubocop) is used for this purpose and its associated editor integrations are highly recommended for contributors.

#### Tests
Please see the more complete document on [testing](testing.md).

#### Translations
Copy translations live at /config/locales and the fallback for missing strings is `en`. [i18n.js](https://github.com/fnando/i18n-js) is used to make these translations available on the frontend. The JS files providing the translations to the front end must be regenerated whenever a change is made by running `rake i18n:js:export`.

## Pre-push checklist
- If you have added any external libraries via a package manager please ensure that you have updated the proper dependency list (`bower.json`, `package.json`, or `Gemfile`).

- If your changes modify the model schema please regenerate `erd.pdf`.

		$ rake erd orientation=vertical
		
- If your changes include copy changes please ensure that you are using the i18n pipeline and that you have regenerated the front-end i18n JS files.

		$ rake i18n:js:export
	
- If your changes modify the JS or CSS of the application (or if you have added external libraries via Bower or NPM) you must rebuild fingerprinted assets (for proper cache busting). This will add some gunk to your `git status`as the old assets will be deleted and the new assets must be added.

		$ gulp build
