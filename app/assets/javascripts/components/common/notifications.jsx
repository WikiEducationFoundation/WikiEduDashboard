import React from 'react';
import createReactClass from 'create-react-class';
import { connect } from "react-redux";

import { removeNotification, NotificationActions } from '../../actions/notification_actions.js';
import NotificationStore from '../../stores/notification_store.js';

const Notifications = createReactClass({
  displayName: 'Notifications',

  mixins: [NotificationStore.mixin],

  getInitialState() {
    return { notifications: NotificationStore.getNotifications() };
  },

  storeDidChange() {
    return this.setState({ notifications: NotificationStore.getNotifications() });
  },

  _handleClose(notification) {
    if (notification.store === 'flux') {
      return NotificationActions.removeNotification(notification);
    }
    return this.props.removeNotification(notification);
  },

  _renderNotification(notification, i) {
    let message;
    let className = 'notice';
    if (notification.type === 'error') {
      message = (
        <p>
          <strong>{I18n.t('application.error')}</strong> {notification.message}
        </p>
      );
    } else if (notification.type === 'success') {
      className = 'notification';
      message = (
        <p>
          {notification.message}
        </p>
      );
    } else {
      message = notification.message;
    }

    let closeIcon;
    if (notification.closable) {
      closeIcon = (
        <svg tabIndex="0" onClick={this._handleClose.bind(this, notification)} viewBox="0 0 24 24" preserveAspectRatio="xMidYMid meet" style={{ fill: 'currentcolor', verticalAlign: 'middle', width: '32px', height: '32px' }}><g><path d="M19 6.41l-1.41-1.41-5.59 5.59-5.59-5.59-1.41 1.41 5.59 5.59-5.59 5.59 1.41 1.41 5.59-5.59 5.59 5.59 1.41-1.41-5.59-5.59z" /></g></svg>
      );
    }

    return (
      <div key={i} className={className}>
        <div className="container">
          {message}
          {closeIcon}
        </div>
      </div>
    );
  },

  render() {
    const allNotifications = this.props.notifications.concat(this.state.notifications);
    const notifications = allNotifications.map((n, i) => this._renderNotification(n, i));

    return (
      <div className="notifications">
        {notifications}
      </div>
    );
  }
});

const mapStateToProps = state => ({
  notifications: state.notifications
});

const mapDispatchToProps = { removeNotification };

export default connect(mapStateToProps, mapDispatchToProps)(Notifications);
