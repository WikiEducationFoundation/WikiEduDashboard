import newsNotifications from '../../app/assets/javascripts/reducers/news_notification';
import { ADD_NEWS_NOTIFICATION, REMOVE_NEWS_NOTIFICATION } from '../../app/assets/javascripts/constants';

describe('newsNotifications reducer', () => {
  it('should return the initial state', () => {
    expect(newsNotifications(undefined, {})).toEqual([]);
  });

  it('should handle ADD_NEWS_NOTIFICATION', () => {
    const initialState = [];
    const notification = 'New notification';

    const action = {
      type: ADD_NEWS_NOTIFICATION,
      notification
    };

    const expectedState = [notification];

    expect(newsNotifications(initialState, action)).toEqual(expectedState);
  });

  it('should handle REMOVE_NEWS_NOTIFICATION', () => {
    const initialState = ['Notification 1', 'Notification 2', 'Notification 3'];
    const notificationToRemove = 'Notification 2';

    const action = {
      type: REMOVE_NEWS_NOTIFICATION,
      notification: notificationToRemove
    };

    const expectedState = ['Notification 1', 'Notification 3'];

    expect(newsNotifications(initialState, action)).toEqual(expectedState);
  });

  it('should handle unknown action type', () => {
    const initialState = ['Notification 1', 'Notification 2'];
    const action = {
      type: 'UNKNOWN_ACTION'
    };

    expect(newsNotifications(initialState, action)).toEqual(initialState);
  });
});
