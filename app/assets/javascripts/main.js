$(() => {
  window.I18n = require('i18n-js');
  require('./utils/course.coffee');
  require('./utils/router.jsx');
  require('events').EventEmitter.defaultMaxListeners = 30;
});
