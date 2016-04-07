import McFly from 'mcfly';
const Flux = new McFly();

const NotificationActions = Flux.createActions({
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

export default NotificationActions;
