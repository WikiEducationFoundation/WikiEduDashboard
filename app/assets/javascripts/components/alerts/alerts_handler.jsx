import React from 'react';
import createReactClass from 'create-react-class';
import PropTypes from 'prop-types';
import { connect } from 'react-redux';

import AlertsList from './alerts_list.jsx';
import { fetchAlerts } from '../../actions/alert_actions';

const AlertsHandler = createReactClass({
  displayName: 'AlertsHandler',


  propTypes: {
    fetchAlerts: PropTypes.func,
    alerts: PropTypes.array
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

  render() {
    let alertList;
    if (this.props.alerts) {
      alertList = (
        <div id="alerts" className="campaign_main alerts container">
          <div className="section-header">
            <h3>{I18n.t('campaign.alert_label')}</h3>
          </div>
          <AlertsList alerts={this.props.alerts} />
        </div>
      );
    }
    return (
      <div>{alertList}</div>
      );
    }
});

const mapStateToProps = state => ({
  alerts: state.alerts.alerts
 });

const mapDispatchToProps = { fetchAlerts };

export default connect(mapStateToProps, mapDispatchToProps)(AlertsHandler);
