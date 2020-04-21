import React from 'react';
import PropTypes from 'prop-types';
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

export default connect(null, mapDispatchToProps)(CampaignAlerts);
