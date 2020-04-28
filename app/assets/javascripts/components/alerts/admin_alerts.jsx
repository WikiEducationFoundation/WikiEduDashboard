import React from 'react';
import PropTypes from 'prop-types';
import { connect } from 'react-redux';

import AlertsHandler from './alerts_handler.jsx';
import { fetchAdminAlerts } from '../../actions/alert_actions';

class AdminAlerts extends React.Component {
  componentDidMount() {
    // This adds ALL alerts to the state, to be used in AlertsHandler
    this.props.fetchAdminAlerts();
  }

  render() {
    return (
      <AlertsHandler
        alertLabel={I18n.t('alerts.alert_label')}
        noAlertsLabel={I18n.t('alerts.no_alerts')}
        adminAlert={true}
      />
    );
  }
}

AdminAlerts.propTypes = {
  fetchAdminAlerts: PropTypes.func,
};

const mapDispatchToProps = { fetchAdminAlerts };

export default connect(null, mapDispatchToProps)(AdminAlerts);
