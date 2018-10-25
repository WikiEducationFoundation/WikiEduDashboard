import React from 'react';
import PropTypes from 'prop-types';
import List from '../common/list.jsx';
import Alert from './alert.jsx';

const AlertsList = ({ alerts, sortBy }) => {
  const elements = alerts.map((alert) => {
    return <Alert alert={alert} key={alert.id} />;
  });

  const keys = {
    created_at: {
      label: I18n.t('campaign.created_at'),
      desktop_only: true
    },
    type: {
      label: I18n.t('campaign.alert_type'),
    },
    course: {
      label: I18n.t('campaign.course'),
      desktop_only: true
    },
    user: {
      label: I18n.t('campaign.alert_user_id'),
      desktop_only: true
    },
    article: {
      label: I18n.t('campaign.alert_article'),
      desktop_only: false
    }
  };

  return (
    <List
      elements={elements}
      keys={keys}
      table_key="alerts"
      none_message={I18n.t('campaign.no_alerts')}
      sortBy={sortBy}
    />
  );
};

AlertsList.propTypes = {
  alerts: PropTypes.array
};

export default AlertsList;
