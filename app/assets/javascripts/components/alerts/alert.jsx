import React from 'react';
import PropTypes from 'prop-types';
import moment from 'moment';

const Alert = ({ alert }) => {
  return (
    <tr className="alert">
      <td className="desktop-only-tc date">{moment(alert.created_at).format('YYYY-MM-DD   h:mm A')}</td>
      <td className="desktop-only-tc">{alert.type}</td>
      <td className="desktop-only-tc"><a target="_blank" href={`/courses/${alert.course_slug}`}>{alert.course}</a></td>
      <td className="desktop-only-tc"><a target="_blank" href={`/users/${alert.user}`}>{alert.user}</a></td>
      <td><a target="_blank" href={alert.article_url}>{alert.article}</a></td>
    </tr>
  );
};

Alert.propTypes = {
  alert: PropTypes.object
};

export default Alert;
