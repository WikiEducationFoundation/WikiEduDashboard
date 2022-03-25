/*
  This file replaces normal main.js when we enable COVERAGE=true in RSpec tests.

  The reason we have a separate version of main.js for coverage is because the
  coverage relies on all the components being embedded in the main bundle.

  The main.js file uses dynamic importing via import() which splits those components into separate files.
  This file instead uses require() which embeds all the required code within main bundle.

  This file should replicate the contents of main.js with the exception that this should have
  require() instead of import() for the above reasons.
*/


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
