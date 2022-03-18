import React from 'react';
import PropTypes from 'prop-types';
import { withRouter } from 'react-router';
import { connect } from 'react-redux';

import AlertsHandler from './alerts_handler.jsx';
import { fetchCampaignAlerts, filterAlerts } from '../../actions/alert_actions';

class CampaignAlerts extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      defaultFilters: [
        { value: 'ArticlesForDeletionAlert', label: 'Articles For Deletion' },
        { value: 'DiscretionarySanctionsEditAlert', label: 'Discretionary Sanctions' }
      ],
    };

    this.getCampaignSlug = this.getCampaignSlug.bind(this);
  }

  componentDidMount() {
    // This clears Rails parts of the previous pages, when changing Campagn tabs
      if (document.getElementById('users')) {
        document.getElementById('users').innerHTML = '';
      }
      if (document.getElementById('campaign-articles')) {
        document.getElementById('campaign-articles').innerHTML = '';
      }
      if (document.getElementById('courses')) {
        document.getElementById('courses').innerHTML = '';
      }
      if (document.getElementById('overview-campaign-details')) {
        document.getElementById('overview-campaign-details').innerHTML = '';
      }

    // This adds the specific campaign alerts to the state, to be used in AlertsHandler
    this.props.fetchCampaignAlerts(this.getCampaignSlug());
    this.props.filterAlerts(this.state.defaultFilters);
  }

  getCampaignSlug() {
    return `${this.props.match.params.campaign_slug}`;
  }

  render() {
    return (
      <AlertsHandler
        alertLabel={I18n.t('campaign.alert_label')}
        noAlertsLabel={I18n.t('campaign.no_alerts')}
      />
    );
  }
}

CampaignAlerts.propTypes = {
  fetchCampaignAlerts: PropTypes.func,
  filterAlerts: PropTypes.func,
};

const mapDispatchToProps = { fetchCampaignAlerts, filterAlerts };

export default withRouter(connect(null, mapDispatchToProps)(CampaignAlerts));
