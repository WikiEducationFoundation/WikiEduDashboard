import { ADD_NEWS_NOTIFICATION } from '~/app/assets/javascripts/constants/news_notification';

export const notificationMessage = (type, message) => ({
  message,
  closable: true,
  type: type === 'Success' ? 'success' : 'error',
});

export const dispatchNotification = (dispatch, type, message) => {
  dispatch({
    type: ADD_NEWS_NOTIFICATION,
    notification: notificationMessage(type, message),
  });
};
