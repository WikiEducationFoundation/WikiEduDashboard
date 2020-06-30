// This file gets added to the page via /app/views/shared/_head
// That Rails view also adds several JavaScript globals to the page,
// including the available locales and wikis, the Features enabled,
// and other static (from a JavaScript perspective) data objects.


// Polyfill
import '@babel/polyfill';

require('location-origin');
require('@rails/ujs').start(); // Enables rails-ujs, which adds JavaScript enhancement to some Rails views

document.addEventListener('DOMContentLoaded', () => {
  window.List = require('list.js'); // List is used for sorting tables outside of React
  require.ensure(
    ['i18n-js', './utils/course.js', './components/app.jsx', 'events', './utils/editable.js', './utils/users_profile.js'],
    (require) => {
      window.I18n = require('i18n-js');
      require('./utils/course.js'); // This adds jquery features for some views outside of React
      // This is the main React entry point. It renders the navbar throughout the app, and
      // renders other components depending on the route.
      require('./components/app.jsx');
      require('events').EventEmitter.defaultMaxListeners = 30;
      require('./utils/editable.js');
      require('./utils/users_profile.js');
    });
});
