import React from 'react';
import NotificationStore from '../../stores/notification_store.coffee';
import NotificationActions from '../../actions/notification_actions.js';

const Notifications = React.createClass({
  mixins: [NotificationStore.mixin],

  getInitialState() {
    return { notifications: NotificationStore.getNotifications() };
  },

  storeDidChange() {
    return this.setState({ notifications: NotificationStore.getNotifications() });
  },

  _handleClose(notification) {
    return NotificationActions.removeNotification(notification);
  },

  _renderNotification(notification, i) {
    let message;
    if (notification.type === 'error') {
      message = (
        <p>
          <strong>{I18n.t('application.error')}</strong> {notification.message}
        </p>
      );
    } else {
      message = notification.message;
    }

    let closeIcon;
    if (notification.closable) {
      closeIcon = (
        <svg tabIndex="0" onClick={this._handleClose.bind(this, notification)} viewBox="0 0 24 24" preserveAspectRatio="xMidYMid meet" style={{ fill: 'currentcolor', verticalAlign: 'middle', width: '32px', height: '32px' }}><g><path d="M19 6.41l-1.41-1.41-5.59 5.59-5.59-5.59-1.41 1.41 5.59 5.59-5.59 5.59 1.41 1.41 5.59-5.59 5.59 5.59 1.41-1.41-5.59-5.59z"></path></g></svg>
      );
    }

    return (
      <div key={i} className="notice">
        <div className="container">
          {message}
          {closeIcon}
        </div>
      </div>
    );
  },

  render() {
    let notifications = this.state.notifications.map((n, i) => this._renderNotification(n, i));

    return (
      <div className="notifications">
        {notifications}
      </div>
    );
  }
});

export default Notifications;
