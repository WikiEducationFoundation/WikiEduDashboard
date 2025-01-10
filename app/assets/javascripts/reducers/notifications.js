import { isEmpty, pull } from 'lodash-es';
import { ADD_NOTIFICATION, REMOVE_NOTIFICATION, API_FAIL, SAVE_TIMELINE_FAIL } from '../constants';

const initialState = [];

const saveTimelineFailedNotification = {
  closable: true,
  type: 'error',
  message: 'The changes you just submitted were not saved. '
           + 'This may happen if the timeline has been changed — '
           + 'by someone else, or by you in another browser '
           + 'window — since the page was loaded. The latest '
           + 'course data has been reloaded, and is ready for '
           + 'you to edit further.'
};

const handleErrorNotification = function (data) {
  const notification = {};

  notification.closable = true;
  notification.type = 'error';

  if (data.responseText) {
    try {
      notification.message = JSON.parse(data.responseText).message;
    } catch (error) {
      // do nothing
    }
  }

  if (!notification.message && data.responseJSON && data.responseJSON.error) {
    notification.message = data.responseJSON.error;
  }

  if (!notification.message) {
    notification.message = data.errors || data.message || data.statusText || data;

    if (typeof notification.message === 'string' && notification.type === 'error' && notification.message.includes('JSONP request')) {
      notification.message = I18n.t('customize_error_message.JSONP_request_failed');
    }
  }

  if (isEmpty(data)) {
    console.error('Error: ', data); // eslint-disable-line no-console
    console.log(data); // eslint-disable-line no-console
  }

  return notification;
};

export default function notifications(state = initialState, action) {
  switch (action.type) {
    case ADD_NOTIFICATION: {
      const newState = [...state, action.notification];

      // Set the maximum number of notifications allowed for each type
      const maxNotifications = 3;

      // Process the state for each notification type (error and success)
      return ['error', 'success'].reduce((acc, type) => {
        // Filter notifications of the current type
        const typeNotifications = acc.filter(x => x.type === type);

        // If we have more than the maximum allowed notifications of this type
        if (typeNotifications.length > maxNotifications) {
          // Find the index of the oldest notification of this type
          const indexToRemove = acc.findIndex(x => x.type === type);
          // Remove the oldest notification by creating a new array without it
          return [...acc.slice(0, indexToRemove), ...acc.slice(indexToRemove + 1)];
        }

        // If we don't need to remove any, return the accumulator unchanged
        return acc;
      }, newState);
    }
    case REMOVE_NOTIFICATION: {
      const newState = [...state];
      pull(newState, action.notification);
      return newState;
    }
    case API_FAIL: {
      // readyState 0 usually indicates that the user navigated away before ajax
      // requests resolved. This is a benign error that should not cause a notification.
      if (action.data.readyState === 0) { return state; }

      const errorNotification = handleErrorNotification(action.data);
      // If the action is silent, return the initial state after logging the error to
      // the console, instead of adding an error notification.
      if (action.silent) { return state; }

      const newState = [...state];

      // Assuming errorNotification is an object, and newState is an array of objects
      const errorNotificationExists = newState.some(
        notification => JSON.stringify(notification) === JSON.stringify(errorNotification)
      );

      if (!errorNotificationExists) {
        newState.push(errorNotification);
      }

      return newState;
    }
    case SAVE_TIMELINE_FAIL: {
      const newState = [...state];
      newState.push(saveTimelineFailedNotification);
      return newState;
    }
    default:
      return state;
  }
}
