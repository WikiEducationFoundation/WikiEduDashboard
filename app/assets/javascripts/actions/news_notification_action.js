import { ADD_NEWS_NOTIFICATION, REMOVE_NEWS_NOTIFICATION } from '../constants';

export const addNotification = notification => ({
  type: ADD_NEWS_NOTIFICATION,
  notification
});

export const removeNotification = notification => ({
  type: REMOVE_NEWS_NOTIFICATION,
  notification
});
