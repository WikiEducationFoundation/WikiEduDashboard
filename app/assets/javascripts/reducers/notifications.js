import _ from 'lodash';
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
      // do nothing nothing
    }
  }

  if (data.responseJSON && data.responseJSON.error) {
    if (!notification.message) { notification.message = data.responseJSON.error; }
  }

  if (!notification.message) { notification.message = data.statusText; }
  if (_.isEmpty(data)) {
    console.error('Error: ', data); // eslint-disable-line no-console
    console.log(data); // eslint-disable-line no-console
  }
  return notification;
};

export default function notifications(state = initialState, action) {
  switch (action.type) {
    case ADD_NOTIFICATION: {
      const newState = [...state];
      newState.push(action.notification);
      return newState;
    }
    case REMOVE_NOTIFICATION: {
      const newState = [...state];
      _.pull(newState, action.notification);
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
      newState.push(errorNotification);
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
