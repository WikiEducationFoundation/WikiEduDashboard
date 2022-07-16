import React from 'react';
import createReactClass from 'create-react-class';
import PropTypes from 'prop-types';
import { connect } from 'react-redux';

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

const AlertsHandler = createReactClass({
  displayName: 'AlertsHandler',

  propTypes: {
    alerts: PropTypes.array,
    alertLabel: PropTypes.string,
    noAlertsLabel: PropTypes.string,
    adminAlert: PropTypes.bool,
    alertTypes: PropTypes.array,
  },

  sortSelect(e) {
    return this.props.sortAlerts(e.target.value);
  },

  filterAlerts(selectedFilters) {
    return this.props.filterAlerts(selectedFilters);
  },

  render() {
    let alertList;
    if (this.props.alerts) {
      alertList = (
        <div id="alerts" className="campaign_main alerts container">
          <div className="section-header">
            <h3>{this.props.alertLabel}</h3>
            <MultiSelectField options={this.props.alertTypes} label={I18n.t('campaign.alert_select_label')} selected={this.props.selectedFilters} setSelectedFilters={this.filterAlerts} />
            <div className="sort-select">
              <select className="sorts" name="sorts" onChange={this.sortSelect}>
                <option value="type">{I18n.t('campaign.alert_type')}</option>
                <option value="course">{I18n.t('campaign.course')}</option>
                <option value="user">{I18n.t('campaign.alert_user_id')}</option>
                <option value="created_at">{I18n.t('campaign.created_at')}</option>
              </select>
            </div>
          </div>
          <AlertsList
            alerts={this.props.selectedAlerts}
            sortBy={this.props.sortAlerts}
            noAlertsLabel={this.props.noAlertsLabel}
            adminAlert={this.props.adminAlert ? this.props.adminAlert : false}
          />
        </div>
      );
    }
    return (
      <div>{alertList}</div>
    );
    }
});

const mapStateToProps = state => ({
  alerts: state.alerts.alerts,
  selectedFilters: state.alerts.selectedFilters,
  selectedAlerts: getFilteredAlerts(state),
  alertTypes: transformAlertsIntoOptions(state.alerts.alerts),
 });

const mapDispatchToProps = { sortAlerts, filterAlerts };

export default connect(mapStateToProps, mapDispatchToProps)(AlertsHandler);
