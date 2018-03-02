import React from 'react';
import createReactClass from 'create-react-class';
import PropTypes from 'prop-types';

const AlertsHandler = createReactClass({
  displayName: 'AlertsHandler',


  propTypes: {
    params: PropTypes.object,
  },


  getCampaignSlug() {
    return `${this.props.params.campaign_slug}`;
  },

  render() {
    const campaignSlug = this.getCampaignSlug();
    return (
      <div>{this.props.campaign_slug}</div>
    );
  }
});

export default AlertsHandler;
