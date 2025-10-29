import React from 'react';
import PropTypes from 'prop-types';
import List from '../common/list.jsx';
import AiAlert from './ai_alert.jsx';

const AiAlertsList = ({ alerts, noAlertsLabel, adminAlert }) => {
  const elements = alerts.map((alert) => {
    return <AiAlert alert={alert} key={alert.id}/>;
  });

  const keys = {
    single_alert_view: {
      label: I18n.t('alerts.ai_stats.single_alert_view'),
      desktop_only: false
    },
    course2: {
      label: I18n.t('campaign.course'),
      desktop_only: true
    },
    user: {
      label: I18n.t('campaign.alert_user_id'),
      desktop_only: true
    },
    revision_diff: {
      label: I18n.t('alerts.ai_stats.revision_diff'),
      desktop_only: false
    },
    pangram_url: {
      label: I18n.t('alerts.ai_stats.pangram_url'),
      desktop_only: true
    }
  };

  if (adminAlert) {
    keys.resolve = {
      label: 'Resolve',
      desktop_only: false
    };
  }

  return (
    <List
      elements={elements}
      keys={keys}
      table_key="alerts"
      none_message={noAlertsLabel}
      stickyHeader={true}
    />
  );
};

AiAlertsList.propTypes = {
  alerts: PropTypes.array,
  noAlertsLabel: PropTypes.string,
  adminAlert: PropTypes.bool,
};

export default AiAlertsList;
