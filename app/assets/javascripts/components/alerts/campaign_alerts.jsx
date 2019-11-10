import React from 'react';
import createReactClass from 'create-react-class';
import PropTypes from 'prop-types';
import { connect } from 'react-redux';

import AlertsHandler from './alerts_handler.jsx';
import { fetchCampaignAlerts, filterAlerts } from '../../actions/alert_actions';

const CampaignAlerts = createReactClass({
  displayName: 'CampaignAlerts',
  propTypes: {
    fetchAlerts: PropTypes.func,
    filterAlerts: PropTypes.func,
  },
  componentWillMount() {
    // This adds the specific campaign alerts to the state, to be used in AlertsHandler
    this.props.fetchCampaignAlerts(this.getCampaignSlug());
    this.props.filterAlerts(this.defaultFilters);
  },
  getCampaignSlug() {
    return `${this.props.match.params.campaign_slug}`;
  },
  defaultFilters: [
    { value: 'ArticlesForDeletionAlert', label: 'Articles For Deletion' },
    { value: 'DiscretionarySanctionsEditAlert', label: 'Discretionary Sanctions' }
  ],
  render() {
    return (
      <AlertsHandler
        alertLabel={I18n.t('campaign.alert_label')}
        noAlertsLabel={I18n.t('campaign.no_alerts')}
      />
    );
  }
});

const mapDispatchToProps = { fetchCampaignAlerts, filterAlerts };

export default connect(null, mapDispatchToProps)(CampaignAlerts);
