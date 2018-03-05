import React from 'react';
import PropTypes from 'prop-types';
import List from '../common/list.jsx';
import Alert from './alert.jsx';

const AlertsList = ({ alerts }) => {
  const elements = alerts.map(alert => {
    return <Alert alert={alert} key={alert.id} />;
  });

  const keys = {
    created_at: {
      label: "Created_at",
      desktop_only: true
    },
    type: {
      label: "Type",
      desktop_only: true
    },
    user_id: {
      label: "User_id",
      desktop_only: true
    },
    resolved: {
      label: "Resolved",
      desktop_only: false
    }
  };

  return (
    <List
      elements={elements}
      keys={keys}
      table_key="alerts"
      none_message="This course has no recent Wikipedia editing activity."
    />
  );
};

AlertsList.propTypes = {
  alerts: PropTypes.array
};

export default AlertsList;
