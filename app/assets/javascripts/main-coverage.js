// This file gets added to the page via /app/views/shared/_head
// That Rails view also adds several JavaScript globals to the page,
// including the available locales and wikis, the Features enabled,
// and other static (from a JavaScript perspective) data objects.


// Polyfill
import '@babel/polyfill';

require('location-origin');
require('@rails/ujs').start(); // Enables rails-ujs, which adds JavaScript enhancement to some Rails views
window.List = require('list.js'); // List is used for sorting tables outside of React

document.addEventListener('DOMContentLoaded', () => {
  /* eslint-disable */
  // We need to bundle everything in main.js instead of loading dynamically
  // because we will be splitting up the modules in main.js for coverage later
  window.I18n = require('i18n-js');
  require('./utils/course.js');
  require('./components/app.jsx');
  require('./utils/editable.js');
  require('./utils/users_profile.js');
  require('events').EventEmitter.defaultMaxListeners = 30;
  /* eslint-enable */
});
