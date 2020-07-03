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
  import('i18n-js').then(({ default: I18n }) => {
    window.I18n = I18n;
  });
  /* eslint-disable */
  import('./utils/course.js'); // This adds jquery features for some views outside of React
  // This is the main React entry point. It renders the navbar throughout the app, and
  // renders other components depending on the route.
  import('./components/app.jsx');
  import('events').then(({default: events}) => {
    events.EventEmitter.defaultMaxListeners = 30;
  });
  import('./utils/editable.js');
  import('./utils/users_profile.js');
  /* eslint-enable */
});
