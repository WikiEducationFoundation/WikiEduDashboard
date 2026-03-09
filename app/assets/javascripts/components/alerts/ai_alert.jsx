import React from 'react';
import PropTypes from 'prop-types';
import { formatDateWithTime } from '../../utils/date_utils';

const AiAlert = ({ alert }) => {
  const redirectToPangram = () => window.open(alert.pangram_url);
  return (
    <tr className="alert">
      <td className="desktop-only-tc"><a target="_blank" href={`/alerts_list/${alert.id}`}>{alert.id}</a></td>
      <td className="desktop-only-tc">{formatDateWithTime(alert.timestamp)}</td>
      <td className="desktop-only-tc"><a target="_blank" href={`/courses/${alert.course_slug}`}>{alert.course}</a></td>
      <td className="desktop-only-tc"><a target="_blank" href={`/users/${alert.user}`}>{alert.user}</a></td>
      <td className="desktop-only-tc"><a target="_blank" href={`${alert.diff_url}`}>{alert.article}</a></td>
      <td className="desktop-only-tc"><button className="button small" onClick={redirectToPangram}>{I18n.t('alerts.ai_stats.go_to_pangram')}</button></td>
    </tr>
  );
};

AiAlert.propTypes = {
  alert: PropTypes.object,
};

export default AiAlert;
