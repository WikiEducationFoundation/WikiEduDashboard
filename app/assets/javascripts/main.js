import { setUserId } from './stores/user_id_store.js';
import { setDefaultCourseType, setCourseStringPrefix } from './stores/course_attributes_store.js';

$(() => {
  window.I18n = require('i18n-js');

  const reactRoot = $('#react_root');
  setDefaultCourseType(reactRoot.data('default-course-type'));
  setCourseStringPrefix(reactRoot.data('course-string-prefix'));

  require('./utils/course.coffee');
  require('./utils/router.jsx');
  require('events').EventEmitter.defaultMaxListeners = 30;
  const main = document.getElementById('main');
  setUserId(main.getAttribute('data-user-id'));
});
