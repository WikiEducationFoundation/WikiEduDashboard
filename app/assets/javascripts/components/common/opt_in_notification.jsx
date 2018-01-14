import React from 'react';
import PropTypes from 'prop-types';

const OptInNotification = ({ notification }) => {
  return (
    <div className="notification">
      <div className="container">
        <p>{notification.message} <a href={notification.read_more_link} target="_blank">{notification.read_more}</a></p>
        <a href={notification.opt_in_link} className="button pull-right">{I18n.t('application.opt_in')}</a>
        <a href={notification.opt_out_link} className="button pull-right">{I18n.t('application.opt_out')}</a>
      </div>
    </div>
  );
};

OptInNotification.propTypes = {
  notification: PropTypes.shape({
    message: PropTypes.string,
    opt_in_link: PropTypes.string,
    opt_out_link: PropTypes.string
  }).isRequired
};

export default OptInNotification;
