import React from 'react';
import { useDispatch, useSelector } from 'react-redux';

import { removeNotification } from '../../actions/notification_actions.js';

export const Notifications = () => {
  const dispatch = useDispatch();
  const notifications = useSelector(state => state.notifications);

  const _handleClose = (notification) => {
    dispatch(removeNotification(notification));
  };

  const _renderNotification = (notification, i) => {
    let message;
    let className = 'notice';
    if (notification.type === 'error') {
      message = (
        <p role="alert">
          <strong>{I18n.t('application.error')}</strong> {notification.message}
        </p>
      );
    } else if (notification.type === 'success') {
      className = 'notification';
      message = (
        <p role="alert">
          {notification.message}
        </p>
      );
    } else {
      message = notification.message;
    }

    return (
      <div key={i} className={className}>
        <div className="container">
          {message}
          {
            notification.closable && <button onClick={() => _handleClose(notification)} className="pull-right icon-close-small" />
          }
        </div>
      </div>
    );
  };

  const renderedNotifs = notifications.map((n, i) => _renderNotification(n, i));

  return (
    <div className="notifications">
      {renderedNotifs}
    </div>
  );
};

export default (Notifications);
