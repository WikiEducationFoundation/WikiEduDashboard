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
  if(!COVERAGE) { // Defined in js.webpack.js
    import('i18n-js').then(({ default: I18n }) => {
      window.I18n = I18n;
    });
    import('./utils/course.js'); // This adds jquery features for some views outside of React
    // This is the main React entry point. It renders the navbar throughout the app, and
    // renders other components depending on the route.
    import('./components/app.jsx');
    import('./utils/editable.js');
    import('./utils/users_profile.js');
    import('events').then(({default: events}) => {
      events.EventEmitter.defaultMaxListeners = 30;
    });
  } else {
    // We need to bundle everything in main.js instead of loading dynamically
    // because we will be splitting up the modules in main.js for coverage later
    window.I18n = require('i18n-js');
    require('./utils/course.js');
    require('./components/app.jsx');
    require('./utils/editable.js');
    require('./utils/users_profile.js');
    require('events').EventEmitter.defaultMaxListeners = 30;
  }
  /* eslint-enable */
});
