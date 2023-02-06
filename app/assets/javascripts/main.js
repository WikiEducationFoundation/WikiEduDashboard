// This file gets added to the page via /app/views/shared/_head
// That Rails view also adds several JavaScript globals to the page,
// including the available locales and wikis, the Features enabled,
// and other static (from a JavaScript perspective) data objects.


// core-js/stable and regenerator-runtime/runtime are directly included to polyfill ES features and to use transpiled generator functions respectively, as @babel/polyfill is deprecated.
import 'core-js/stable';
import 'regenerator-runtime/runtime';

require('location-origin');
require('@rails/ujs').start(); // Enables rails-ujs, which adds JavaScript enhancement to some Rails views
window.List = require('list.js'); // List is used for sorting tables outside of React

document.addEventListener('DOMContentLoaded', () => {
  /* eslint-disable */
  import('./utils/course.js'); // This adds jquery features for some views outside of React
  
  // This is the main React entry point. It renders the navbar throughout the app, and
  // renders other components depending on the route.
  import('./components/app.jsx');
  import('events').then(({default: events}) => {
    events.EventEmitter.defaultMaxListeners = 30;
  });
    /* eslint-enable */
});
