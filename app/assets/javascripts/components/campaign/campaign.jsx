import { Route, Switch } from 'react-router-dom';
import { withRouter } from 'react-router';
import React from 'react';
import createReactClass from 'create-react-class';
import { connect } from 'react-redux';
import PropTypes from 'prop-types';
import { getCampaign } from '../../actions/campaign_view_actions';
import CampaignAlerts from '../alerts/campaign_alerts.jsx';
import CampaignOresPlot from './campaign_ores_plot.jsx';
import CampaignOverviewHandler from './campaign_overview_handler';
import CampaignNavbar from '../common/campaign_navbar';
import CampaignStats from './campaign_stats';

export const Campaign = createReactClass({
  displayName: 'Campaign',

  propTypes: {
    campaign: PropTypes.object.isRequired,
    match: PropTypes.object,
  },

  componentDidMount() {
    const campaignSlug = this.props.match.params.campaign_slug;
    return this.props.getCampaign(campaignSlug);
  },

  render() {
    if (this.props.campaign.loading) {
      return <div />;
    }
    if (window.location.href.match(/overview/)) {
      return (
        <div>
          <CampaignStats campaign={this.props.campaign} />
          <div className="stats-download-modal">
            <CampaignOverviewHandler {...this.props} />
          </div>
        </div>);
    }

    let navBar;
  if (window.location.href.match(/ores_plot/) || window.location.href.match(/alerts/)) {
    navBar = (<CampaignNavbar
      campaign={this.props.campaign}
    />);
  }
    return (
      <div>
        {navBar}
        <div className="container">
          <section className="overview container">
            <CampaignStats campaign={this.props.campaign} />
            <Switch>
              <Route exact path="/campaigns/:campaign_slug/ores_plot" component={CampaignOresPlot} />
              <Route exact path="/campaigns/:campaign_slug/alerts" component={CampaignAlerts} />
            </Switch>
          </section>
        </div>
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
