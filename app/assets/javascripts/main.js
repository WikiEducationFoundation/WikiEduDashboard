import './main-utils';

$(function() {
  let I18n;
  window.I18n = I18n = require('i18n-js');
  require("./utils/course.coffee");
  require("./utils/router.jsx");
  return require("events").EventEmitter.defaultMaxListeners = 30;
});
