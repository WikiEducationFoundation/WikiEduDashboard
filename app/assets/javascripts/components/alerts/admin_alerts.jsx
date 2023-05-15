import React, { useEffect } from 'react';
import PropTypes from 'prop-types';
import { useDispatch } from 'react-redux';

import AlertsHandler from './alerts_handler.jsx';
import { fetchAdminAlerts } from '../../actions/alert_actions';

const AdminAlerts = () => {
  const dispatch = useDispatch();

  useEffect(() => {
    // This adds ALL alerts to the state, to be used in AlertsHandler
    dispatch(fetchAdminAlerts());
  }, [dispatch]);


  return (
    <AlertsHandler
      alertLabel={I18n.t('alerts.alert_label')}
      noAlertsLabel={I18n.t('alerts.no_alerts')}
      adminAlert={true}
    />
  );
};

AdminAlerts.propTypes = {
  fetchAdminAlerts: PropTypes.func,
};

export default (AdminAlerts);
