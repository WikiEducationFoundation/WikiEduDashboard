// Polyfills
import "babel-polyfill";
import Rails from 'rails-ujs';
require('location-origin');
require('trix');
Rails.start();

$(() => {
  window.I18n = require('i18n-js');
  window.List = require('list.js');
  require('./utils/course.js');
  require('./utils/router.jsx');
  require('events').EventEmitter.defaultMaxListeners = 30;
  require('./utils/editable.js');
  require('./utils/users_profile.js');
});
