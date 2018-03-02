import React from 'react';
import createReactClass from 'create-react-class';
import PropTypes from 'prop-types';
import { connect } from 'react-redux';

import { fetchAlerts } from '../../actions/alert_actions';

const AlertsHandler = createReactClass({
  displayName: 'AlertsHandler',


  propTypes: {
    params: PropTypes.object,
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
    console.log(this.props.alerts);
    return (
      <div>"Hola"</div>
    );
  }
});

const mapStateToProps = state => ({
  alerts: state.alerts.alerts
 });

const mapDispatchToProps = { fetchAlerts };

export default connect(mapStateToProps, mapDispatchToProps)(AlertsHandler);
