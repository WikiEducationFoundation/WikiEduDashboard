[Back to README](../README.md)

## Contributing

#### Developer Resources

- [MediaWiki API Manual](https://www.mediawiki.org/wiki/Manual:Contents)
- [MediaWiki API Sandbox](https://en.wikipedia.org/wiki/Special%3aApiSandbox)
- [Quarry](http://quarry.wmflabs.org/): Public querying interface for the Labs replica database. Very useful for testing SQL queries and for figuring out what data is available.

#### Code Style
This project adheres as strictly as possible to the community [Ruby Style Guide](https://github.com/bbatsov/ruby-style-guide). [Rubocop](https://github.com/bbatsov/rubocop) is used for this purpose and its associated editor integrations are highly recommended for contributors.

#### Tests
Tests reside in the `/spec` folder. Both unit and integration tests are driven by [RSpec](https://github.com/rspec/rspec).

* Write unit tests before building new features whenever possible. This project uses [RSpec](https://github.com/rspec/rspec) in conjuction with [SimpleCov](https://github.com/colszowka/simplecov) for unit testing. 
* Write integration tests for new interfaces. This project uses [Capybara](https://github.com/jnicklas/capybara), [Capybara-webkit](https://github.com/thoughtbot/capybara-webkit), and [Selenium](https://github.com/SeleniumHQ/selenium) for integration testing.
    * Integration tests require [qt5](https://www.qt.io/). On OSX you will need to uninstall qt4, install qt5, and add a symlink. [This wiki section](https://github.com/thoughtbot/capybara-webkit/wiki/Installing-Qt-and-compiling-capybara-webkit#video-playback-mp4-on-osx-requires-qt-5) is a useful reference.
* Install test dependencies: `apt-get install pandoc`

#### Translations
Copy translations live at /config/locales and the fallback for missing strings is `en`. [i18n.js](https://github.com/fnando/i18n-js) is used to make these translations available on the frontend. The JS files providing the translations to the front end must be regenerated whenever a change is made by running `rake i18n:js:export`.

## Pre-push checklist
- If your changes modify the model schema please regenerate `erd.pdf`.

		$ rake erd orientation=vertical
		
- If your changes include copy changes please ensure that you are using the i18n pipeline and that you have regenerated the front-end i18n JS files.

		$ rake i18n:js:export
	
- If your changes modify the JS or CSS of the application you must rebuild fingerprinted assets (for proper cache busting). This will add some gunk to your `git status`as the old assets will be deleted and the new assets must be added.

		$ gulp build