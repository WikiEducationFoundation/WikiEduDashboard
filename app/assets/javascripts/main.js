// This file gets added to the page via /app/views/shared/_head
// That Rails view also adds several JavaScript globals to the page,
// including the available locales and wikis, the Features enabled,
// and other static (from a JavaScript perspective) data objects.

// Polyfills
import "babel-polyfill";
import Rails from 'rails-ujs';
require('location-origin');
Rails.start(); // Enables rails-ujs, which adds JavaScript enhancement to some Rails views

$(() => {
  window.I18n = require('i18n-js');
  window.List = require('list.js'); // List is used for sorting tables outside of React
  require('./utils/course.js'); // This adds jquery features for some views outside of React
  // This is the main React entry point. It renders the navbar throughout the app, and
  // renders other components depending on the route.
  require('./utils/router.jsx');
  require('events').EventEmitter.defaultMaxListeners = 30;
  require('./utils/editable.js');
  require('./utils/users_profile.js');
});
