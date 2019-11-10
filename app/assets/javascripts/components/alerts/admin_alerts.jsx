import React from 'react';
import createReactClass from 'create-react-class';
import PropTypes from 'prop-types';
import { connect } from 'react-redux';

import AlertsHandler from './alerts_handler.jsx';
import { fetchAdminAlerts } from '../../actions/alert_actions';

const AdminAlerts = createReactClass({
  displayName: 'AdminAlerts',
  propTypes: {
    fetchAlerts: PropTypes.func,
  },
  componentWillMount() {
    // This adds ALL alerts to the state, to be used in AlertsHandler
    this.props.fetchAdminAlerts();
  },
  render() {
    return (
      <AlertsHandler
        alertLabel={I18n.t('alerts.alert_label')}
        noAlertsLabel={I18n.t('alerts.no_alerts')}
        adminAlert={true}
      />
    );
  }
});

const mapDispatchToProps = { fetchAdminAlerts };

export default connect(null, mapDispatchToProps)(AdminAlerts);
