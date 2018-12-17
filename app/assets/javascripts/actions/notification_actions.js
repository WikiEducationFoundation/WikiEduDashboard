import { ADD_NOTIFICATION, REMOVE_NOTIFICATION } from '../constants';

export const addNotification = notification => ({
  type: ADD_NOTIFICATION,
  notification
});

export const removeNotification = notification => ({
  type: REMOVE_NOTIFICATION,
  notification
});
