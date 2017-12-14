import _ from 'lodash';
import { ADD_NOTIFICATION, REMOVE_NOTIFICATION, API_FAIL } from "../constants";

const initialState = [];

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

      const newState = [...state];
      const errorNotification = handleErrorNotification(action.data);
      newState.push(errorNotification);
      return newState;
    }
    default:
      return state;
  }
}
