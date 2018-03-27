import React from 'react';
import createReactClass from 'create-react-class';
import PropTypes from 'prop-types';
import { connect } from 'react-redux';

import AlertsList from './alerts_list.jsx';
import { fetchAlerts, sortAlerts, filterAlerts } from '../../actions/alert_actions';
import MultiSelectField from '../common/multi_select_field.jsx';

const ALERTS = [
  { label: 'ActiveCourseAlert', value: 'ActiveCourseAlert' },
  { label: 'ArticlesForDeletionAlert', value: 'ArticlesForDeletionAlert' },
  { label: 'BlockedEditsAlert', value: 'BlockedEditsAlert' },
  { label: 'ContinuedCourseActivityAlert', value: 'ContinuedCourseActivityAlert' },
  { label: 'DeletedUploadsAlert', value: 'DeletedUploadsAlert' },
  { label: 'DiscretionarySanctionsEditAlert', value: 'DiscretionarySanctionsEditAlert' },
  { label: 'DYKNominationAlert', value: 'DYKNominationAlert' },
  { label: 'GANominationAlert', value: 'GANominationAlert' },
  { label: 'NoEnrolledStudentsAlert', value: 'NoEnrolledStudentsAlert' },
  { label: 'ProductiveCourseAlert', value: 'ProductiveCourseAlert' },
  { label: 'UnsubmittedCourseAlert', value: 'UnsubmittedCourseAlert' },
  { label: 'UntrainedStudentsAlert', value: 'UntrainedStudentsAlert' },
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
            <MultiSelectField options={ALERTS} selected={this.props.selectedFilters} setSelectedFilters={this.filterAlerts} />
            <div className="sort-select">
              <select className="sorts" name="sorts" onChange={this.sortSelect}>
                <option value="type">{I18n.t('campaign.alert_type')}</option>
                <option value="course">{I18n.t('campaign.course')}</option>
                <option value="user">{I18n.t('campaign.alert_user_id')}</option>
                <option value="created_at">{I18n.t('campaign.created_at')}</option>
              </select>
            </div>
          </div>
          <AlertsList alerts={this.props.selectedAlerts} />
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
  selectedAlerts: state.alerts.selectedAlerts,
 });

const mapDispatchToProps = { fetchAlerts, sortAlerts, filterAlerts };

export default connect(mapStateToProps, mapDispatchToProps)(AlertsHandler);
