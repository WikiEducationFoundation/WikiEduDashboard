[Back to README](../README.md)

---

## Contributing
#### Code Style
This project adheres as strictly as possible to the community [Ruby Style Guide](https://github.com/bbatsov/ruby-style-guide). [Rubocop](https://github.com/bbatsov/rubocop) is used for this purpose and its associated editor integrations are highly recommended for contributors.

#### Tests
Tests reside in the `/spec` folder. Both unit and integration tests are driven by [RSpec](https://github.com/rspec/rspec).
* Write unit tests before building new features whenever possible. This project uses [RSpec](https://github.com/rspec/rspec) in conjuction with [SimpleCov](https://github.com/colszowka/simplecov) for unit testing. 
* Write integration tests for new interfaces. This project uses [Capybara](https://github.com/jnicklas/capybara) and [Capybara-webkit](https://github.com/thoughtbot/capybara-webkit) for integration testing.
    * Integration tests require [qt5](https://www.qt.io/). On OSX you will need to uninstall qt4, install qt5, and add a symlink. [This wiki section](https://github.com/thoughtbot/capybara-webkit/wiki/Installing-Qt-and-compiling-capybara-webkit#video-playback-mp4-on-osx-requires-qt-5) is a useful reference.
* Install test dependencies: `apt-get install pandoc`

#### Translations
Copy translations live at /config/locales and the fallback for missing strings is `en`. [i18n.js](https://github.com/fnando/i18n-js) is used to make these translations available on the frontend. The JS files providing the translations to the front end must be regenerated whenever a change is made by running `rake i18n:js:export`.
