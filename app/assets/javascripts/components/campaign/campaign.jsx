// /* eslint no-undef: 2 */
import { Route, Switch } from 'react-router-dom';
import { withRouter } from 'react-router';
import React from 'react';
import createReactClass from 'create-react-class';
import { connect } from 'react-redux';
import PropTypes from 'prop-types';
import CampaignNavbar from '../common/campaign_navbar.jsx';
import { getCampaign } from '../../actions/campaign_view_actions';
import CampaignAlerts from '../alerts/campaign_alerts.jsx';
import CampaignOresPlot from './campaign_ores_plot.jsx';

export const Campaign = createReactClass({
  displayName: 'Campaign',

  propTypes: {
    campaign: PropTypes.object.isRequired,
    match: PropTypes.object,
  },

  componentDidMount() {
    const campaignSlug = this.props.match.params.slug;
    return this.props.getCampaign(campaignSlug);
  },

  render() {
    if (this.props.campaign.loading) {
      return <div />;
    }
    const campaignProps = { campaign: this.props.campaign, match: this.props.match };
    return (
      <div>
        <CampaignNavbar
          campaign={this.props.campaign}
        />
        <Switch>
          <Route exact path="/campaigns/:campaign_slug/ores_plot" render={() => <CampaignOresPlot {...campaignProps} />} />
          <Route exact path="/campaigns/:campaign_slug/alerts" render={() => <CampaignAlerts {...campaignProps} />} />
        </Switch>
      </div >
    );
  }
});

const mapStateToProps = state => ({
  campaign: state.campaign,
});

const mapDispatchToProps = {
  getCampaign
};

export default withRouter(connect(mapStateToProps, mapDispatchToProps)(Campaign));
