import React from 'react';
import PropTypes from 'prop-types';
import { connect } from 'react-redux';

import { handleResolveAlert } from '../../actions/alert_actions';
import { formatWithTime } from '../../utils/date_utils';

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
        <button className="button small danger dark" onClick={() => resolveAlert(alert.id)}>Resolve</button>
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
    alertTypeCell = <td className="alert-type">{alert.type}</td>;
  }

  return (
    <tr className="alert">
      <td className="desktop-only-tc date">{formatWithTime(alert.created_at)}</td>
      {alertTypeCell}
      <td className="desktop-only-tc"><a target="_blank" href={`/courses/${alert.course_slug}`}>{alert.course}</a></td>
      <td className="desktop-only-tc"><a target="_blank" href={`/users/${alert.user}`}>{alert.user}</a></td>
      <td><a target="_blank" href={alert.article_url}>{alert.article}</a></td>
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
