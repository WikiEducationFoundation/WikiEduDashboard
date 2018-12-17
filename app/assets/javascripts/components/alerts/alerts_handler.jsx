import React from 'react';
import createReactClass from 'create-react-class';
import PropTypes from 'prop-types';
import { connect } from 'react-redux';

import AlertsList from './alerts_list.jsx';
import { fetchAlerts, sortAlerts, filterAlerts } from '../../actions/alert_actions';
import MultiSelectField from '../common/multi_select_field.jsx';
import { getFilteredAlerts } from '../../selectors';

const ALERTS = [
  { label: 'Active Course', value: 'ActiveCourseAlert' },
  { label: 'Articles For Deletion', value: 'ArticlesForDeletionAlert' },
  { label: 'Blocked Edits', value: 'BlockedEditsAlert' },
  { label: 'Blocked User', value: 'BlockedUserAlert' },
  { label: 'Continued Course Activity', value: 'ContinuedCourseActivityAlert' },
  { label: 'Deleted Uploads', value: 'DeletedUploadsAlert' },
  { label: 'Discretionary Sanctions Edit', value: 'DiscretionarySanctionsEditAlert' },
  { label: 'DYK Nomination', value: 'DYKNominationAlert' },
  { label: 'GA Nomination', value: 'GANominationAlert' },
  { label: 'No Enrolled Students', value: 'NoEnrolledStudentsAlert' },
  { label: 'Productive Course', value: 'ProductiveCourseAlert' },
  { label: 'Unsubmitted Course', value: 'UnsubmittedCourseAlert' },
  { label: 'Untrained Students', value: 'UntrainedStudentsAlert' },
];

const AlertsHandler = createReactClass({
  displayName: 'AlertsHandler',

  propTypes: {
    fetchAlerts: PropTypes.func,
    alerts: PropTypes.array,
  },

  componentWillMount() {
    const campaignSlug = this.getCampaignSlug();
    return this.props.fetchAlerts(campaignSlug);
  },

  getCampaignSlug() {
    return `${this.props.params.campaign_slug}`;
  },

  fetchAlerts(campaignSlug) {
    this.props.fetchAlerts(campaignSlug);
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
            <h3>{I18n.t('campaign.alert_label')}</h3>
            <MultiSelectField options={ALERTS} label={I18n.t('campaign.alert_select_label')} selected={this.props.selectedFilters} setSelectedFilters={this.filterAlerts} />
            <div className="sort-select">
              <select className="sorts" name="sorts" onChange={this.sortSelect}>
                <option value="type">{I18n.t('campaign.alert_type')}</option>
                <option value="course">{I18n.t('campaign.course')}</option>
                <option value="user">{I18n.t('campaign.alert_user_id')}</option>
                <option value="created_at">{I18n.t('campaign.created_at')}</option>
              </select>
            </div>
          </div>
          <AlertsList alerts={this.props.selectedAlerts} sortBy={this.props.sortAlerts} />
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
 });

const mapDispatchToProps = { fetchAlerts, sortAlerts, filterAlerts };

export default connect(mapStateToProps, mapDispatchToProps)(AlertsHandler);
