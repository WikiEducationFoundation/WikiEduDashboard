import React from 'react';
import PropTypes from 'prop-types';
import List from '../common/list.jsx';
import AiAlert from './ai_alert.jsx';

const AiAlertsList = ({ alerts, noAlertsLabel }) => {
  const elements = alerts.map((alert) => {
    return <AiAlert alert={alert} key={alert.id}/>;
  });

  const keys = {
    single_alert_view: {
      label: I18n.t('alerts.ai_stats.single_alert_view')
    },
    timestamp: {
      label: I18n.t('alerts.ai_stats.timestamp')
    },
    course2: {
      label: I18n.t('campaign.course')
    },
    user: {
      label: I18n.t('campaign.alert_user_id')
    },
    revision_diff: {
      label: I18n.t('alerts.ai_stats.revision_diff')
    },
    pangram_url: {
      label: I18n.t('alerts.ai_stats.pangram_url')
    }
  };

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
};

export default AiAlertsList;
