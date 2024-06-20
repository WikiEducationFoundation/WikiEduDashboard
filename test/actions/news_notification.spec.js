import { addNotification, removeNotification } from '../../app/assets/javascripts/actions/news_notification_action';
import { ADD_NEWS_NOTIFICATION, REMOVE_NEWS_NOTIFICATION } from '../../app/assets/javascripts/constants';


describe('News Notification Actions', () => {
  it('should create an action to add a news notification', () => {
    const notification = { id: 1, message: 'New news notification!' };
    const expectedAction = {
      type: ADD_NEWS_NOTIFICATION,
      notification
    };
    expect(addNotification(notification)).toEqual(expectedAction);
  });

  it('should create an action to remove a news notification', () => {
    const notification = { id: 1, message: 'Remove this notification' };
    const expectedAction = {
      type: REMOVE_NEWS_NOTIFICATION,
      notification
    };
    expect(removeNotification(notification)).toEqual(expectedAction);
  });
});
