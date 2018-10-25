// Requirements
//----------------------------------------

import McFly from 'mcfly';
import _ from 'lodash';

const Flux = new McFly();


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

const handleErrorNotification = function (data) {
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

      handleErrorNotification(data);
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
