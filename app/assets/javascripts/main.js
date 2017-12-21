// Polyfills
import "babel-polyfill";
require('location-origin');

$(() => {
  window.I18n = require('i18n-js');

  require('./utils/course.js');
  require('./utils/router.jsx');
  require('events').EventEmitter.defaultMaxListeners = 30;
  require('./utils/language_switcher.js');
  require('./utils/editable.js');
  require('./utils/users_profile.js');
});
