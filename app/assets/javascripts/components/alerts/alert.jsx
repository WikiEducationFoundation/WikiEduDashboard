import React from 'react';
import PropTypes from 'prop-types';
import moment from 'moment';

const Alert = ({ alert }) => {
  return (
    <tr className="alert">
      <td className="desktop-only-tc date">{moment(alert.created_at).format('YYYY-MM-DD   h:mm A')}</td>
      <td className="desktop-only-tc">{alert.type}</td>
      <td className="desktop-only-tc">{alert.course_id}</td>
      <td className="desktop-only-tc">{alert.user_id}</td>
      <td className="desktop-only-tc">{alert.resolved}</td>
    </tr>
  );
};

Alert.propTypes = {
  alert: PropTypes.object
};

export default Alert;
