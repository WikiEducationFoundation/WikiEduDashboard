import React from 'react';
import PropTypes from 'prop-types';
import { connect } from 'react-redux';

import { handleResolveAlert } from '../../actions/alert_actions';
import { formatDateWithTime } from '../../utils/date_utils';

const Alert = ({ alert, adminAlert, resolveAlert }) => {
  let resolveCell;
  let alertTypeCell;

  if (adminAlert) {
    let resolveText;
    let resolveButton;
    if (alert.resolved) {
      resolveText = '✓';
    }
    if (alert.resolvable && !alert.resolved) {
      resolveButton = (
        <button className="button small danger dark" onClick={() => resolveAlert(alert.id)}>{I18n.t('campaign.resolve')}</button>
      );
    }
    resolveCell = (
      <td className="desktop-only-tc">{resolveText} {resolveButton}</td>
    );
    alertTypeCell = (
      <td className="alert-type">
        <a href={`/alerts_list/${alert.id}`}>{alert.type}</a>
      </td>
    );
  } else {
    alertTypeCell = <td className="alert-type"><a href={`/alerts_list/${alert.id}`} >{alert.type}</a></td>;
  }

  const courseCell = alert.course_slug
    ? <a target="_blank" href={`/courses/${alert.course_slug}`}>{alert.course}</a>
    : null;
  const userCell = alert.user
    ? <a target="_blank" href={`/users/${alert.user}`}>{alert.user}</a>
    : null;
  const articleCell = alert.article_url
    ? <a target="_blank" href={alert.article_url}>{alert.article}</a>
    : alert.article;

  return (
    <tr className="alert">
      <td className="desktop-only-tc date">{formatDateWithTime(alert.created_at)}</td>
      {alertTypeCell}
      <td className="desktop-only-tc">{courseCell}</td>
      <td className="desktop-only-tc">{userCell}</td>
      <td>{articleCell}</td>
      {resolveCell}
    </tr>
  );
};

Alert.propTypes = {
  alert: PropTypes.object,
  adminAlert: PropTypes.bool,
  resolveAlert: PropTypes.func,
};

const mapDispatchToProps = { resolveAlert: handleResolveAlert };

export default connect(null, mapDispatchToProps)(Alert);
