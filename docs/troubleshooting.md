[Back to README](../README.md)

## Common setup issues

- **Most integration tests fail with an exception.** This is usually caused by an improperly installed/linked version of QT, particularly on OSX. [This wiki section](https://github.com/thoughtbot/capybara-webkit/wiki/Installing-Qt-and-compiling-capybara-webkit#video-playback-mp4-on-osx-requires-qt-5) should set you straight.

- **Timeout in "before all" hook when running `npm test`** This is caused when you allot very few resources to `npm test`. It takes too long and times out. You can increase the timeout limit in `test/mocha.opts` by adding `-t 5000` of allot more resources to run it faster.

- **"Error: EACCES: permission denied, open '/home/username/.babel.json'"** This happen, when babel don't have acces to ~/. To fix this, use command: `BABEL_DISABLE_CACHE=1 gulp`
