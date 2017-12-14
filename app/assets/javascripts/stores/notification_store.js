// Requirements
//----------------------------------------

import McFly from 'mcfly';
const Flux = new McFly();
import _ from 'lodash';

import CourseStore from './course_store.js';
import ServerActions from '../actions/server_actions.js';

// Data
//----------------------------------------

const _notifications = [];


// Private Methods
//----------------------------------------

const addNotification = function (notification) {
  _notifications.push({ store: 'flux', ...notification });
};

const removeNotification = function (notification) {
  _.pull(_notifications, notification);
};

const handleErrorNotification = function (data, actionType) {
  const notification = {};
  notification.closable = true;
  notification.type = 'error';
  if (data.responseText) {
    try {
      notification.message = JSON.parse(data.responseText).message;
    } catch (error) {
      // do nothing nothing
    }
  }

  if (data.responseJSON && data.responseJSON.error) {
    if (!notification.message) { notification.message = data.responseJSON.error; }
  }

  if (!notification.message) { notification.message = data.statusText; }

  if (actionType === 'SAVE_TIMELINE_FAIL') {
    const courseId = CourseStore.getCourse().slug;
    ServerActions.fetch('course', courseId);
    ServerActions.fetch('timeline', courseId);
    notification.message = 'The changes you just submitted were not saved. ' +
                           'This may happen if the timeline has been changed — ' +
                           'by someone else, or by you in another browser ' +
                           'window — since the page was loaded. The latest ' +
                           'course data has been reloaded, and is ready for ' +
                           'you to edit further.';
  }

  addNotification(notification);
};

// Store
//----------------------------------------

const storeMethods = {
  clearNotifications() {
    return _notifications.length = 0;
  },
  getNotifications() {
    return _notifications;
  }
};

const NotificationStore = Flux.createStore(storeMethods, (payload) => {
  const { data } = payload;
  switch (payload.actionType) {
    case 'REMOVE_NOTIFICATION':
      removeNotification(payload.notification);
      NotificationStore.emitChange();
      break;
    case 'ADD_NOTIFICATION':
      addNotification(payload.notification);
      NotificationStore.emitChange();
      break;
    case 'API_FAIL': case 'SAVE_TIMELINE_FAIL':
      // readyState 0 usually indicates that the user navigated away before ajax
      // requests resolved. This is a benign error that should not cause a notification.
      if (data.readyState === 0) { return; }

      handleErrorNotification(data, payload.actionType);
      NotificationStore.emitChange();
      break;
    case 'NEEDS_UPDATE':
      addNotification({
        message: payload.data.result,
        closable: true,
        type: 'success'
      });

      NotificationStore.emitChange();
      break;
    default:
      // no default
  }

  return true;
});


// Exports
//----------------------------------------

export default NotificationStore;
