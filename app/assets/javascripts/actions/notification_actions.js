import McFly from 'mcfly';
const Flux = new McFly();

import { ADD_NOTIFICATION, REMOVE_NOTIFICATION } from "../constants";

export const addNotification = (notification) => ({
  type: ADD_NOTIFICATION,
  notification
});

export const removeNotification = (notification) => ({
  type: REMOVE_NOTIFICATION,
  notification
});

// Deprecated flux action
export const NotificationActions = Flux.createActions({
  removeNotification(notification) {
    return {
      actionType: 'REMOVE_NOTIFICATION',
      notification
    };
  },

  addNotification(notification) {
    return {
      actionType: 'ADD_NOTIFICATION',
      notification
    };
  }
});
