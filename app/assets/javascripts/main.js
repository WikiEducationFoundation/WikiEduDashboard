import { setUserId } from './stores/user_id_store.js';
import { setDefaultCourseType, setCourseStringPrefix, setUseStartAndEndTimes } from './stores/course_attributes_store.js';

$(() => {
  window.I18n = require('i18n-js');

  const $reactRoot = $('#react_root');
  setDefaultCourseType($reactRoot.data('default-course-type'));
  setCourseStringPrefix($reactRoot.data('course-string-prefix'));
  setUseStartAndEndTimes($reactRoot.data('use-start-and-end-times'));
  const $main = $('#main');
  setUserId($main.data('user-id'));

  require('./utils/course.js');
  require('./utils/router.jsx');
  require('events').EventEmitter.defaultMaxListeners = 30;
  require('./utils/language_switcher.js');
  require('./utils/editable.js');
  require('./utils/users_profile.js');
  require('./utils/hamburger_menu.js');
});

// Polyfills
require('location-origin');
