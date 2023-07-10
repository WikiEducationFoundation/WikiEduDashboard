import React from 'react';
import PropTypes from 'prop-types';
import { useDispatch, useSelector } from 'react-redux';

import AlertsList from './alerts_list.jsx';
import { sortAlerts, filterAlerts } from '../../actions/alert_actions';
import MultiSelectField from '../common/multi_select_field.jsx';
import { getFilteredAlerts } from '../../selectors';

// This helper function takes in an array of alert objects as input,
// it outputs an array of objects in the format { label: '', value: '' }
// to be used by the MultiSelectField component
const transformAlertsIntoOptions = (alertsArray) => {
  if (alertsArray.length === 0) return [];

  return alertsArray.map((item) => {
    const value = item.type;
    const labelWordArray = value.split(/(?=[A-Z][a-z])/);
    labelWordArray.pop();
    const label = labelWordArray.join(' ');

    return { label, value };
  }).filter((elem, index, self) => {
    return self.findIndex((t) => {
      return (t.label === elem.label);
    }) === index;
  });
};

const AlertsHandler = ({ alertLabel, noAlertsLabel, adminAlert }) => {
  const dispatch = useDispatch();
  const alerts = useSelector(state => state.alerts.alerts);
  const selectedFilters = useSelector(state => state.alerts.selectedFilters);
  const selectedAlerts = useSelector(state => getFilteredAlerts(state));
  const alertTypes = useSelector(state => transformAlertsIntoOptions(state.alerts.alerts));

  const sortSelect = (e) => {
    return dispatch(sortAlerts(e.target.value));
  };

  let alertList;
  if (alerts) {
    alertList = (
      <div id="alerts" className="campaign_main alerts container">
        <div className="section-header">
          <h3>{alertLabel}</h3>
          <MultiSelectField options={alertTypes} label={I18n.t('campaign.alert_select_label')} selected={selectedFilters} setSelectedFilters={value => dispatch(filterAlerts(value))} />
          <div className="sort-select">
            <select className="sorts" name="sorts" onChange={sortSelect}>
              <option value="type">{I18n.t('campaign.alert_type')}</option>
              <option value="course">{I18n.t('campaign.course')}</option>
              <option value="user">{I18n.t('campaign.alert_user_id')}</option>
              <option value="created_at">{I18n.t('campaign.created_at')}</option>
            </select>
          </div>
        </div>
        <AlertsList
          alerts={selectedAlerts}
          sortBy={key => dispatch(sortAlerts(key))}
          noAlertsLabel={noAlertsLabel}
          adminAlert={adminAlert || false}
        />
      </div>
    );
  }
  return (
    <div>{alertList}</div>
  );
};


AlertsHandler.propTypes = {
  alerts: PropTypes.array,
  alertLabel: PropTypes.string,
  noAlertsLabel: PropTypes.string,
  adminAlert: PropTypes.bool,
  alertTypes: PropTypes.array,
};

export default (AlertsHandler);
