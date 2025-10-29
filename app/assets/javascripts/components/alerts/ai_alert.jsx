import React from 'react';
import PropTypes from 'prop-types';

const AiAlert = ({ alert }) => {
  return (
    <tr className="alert">
      <td className="desktop-only-tc"><a target="_blank" href={`/alerts_list/${alert.id}`}>{alert.id}</a></td>
      <td className="desktop-only-tc"><a target="_blank" href={`/courses/${alert.course_slug}`}>{alert.course}</a></td>
      <td className="desktop-only-tc"><a target="_blank" href={`/users/${alert.user}`}>{alert.user}</a></td>
      <td className="desktop-only-tc"><a target="_blank" href={`${alert.diff_url}`}>{alert.article}</a></td>
      <td className="desktop-only-tc"><a target="_blank" href={`${alert.pangram_url}`}>{alert.pangram_url}</a></td>
    </tr>
  );
};

AiAlert.propTypes = {
  alert: PropTypes.object,
};

export default AiAlert;
