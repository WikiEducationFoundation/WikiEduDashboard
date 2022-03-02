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

    let campaignHandler;
    if (window.location.href.match(/overview/)) {
      const modalClass = document.getElementById('low_modal') ? 'low-modal' : 'low-modal sidebar-correction';
      campaignHandler = (
        <div className={modalClass}>
          <CampaignOverviewHandler {...this.props} />
        </div>
        );
    }

    if (window.location.href.match(/programs/)) {
      return (
        <div>
          <CampaignNavbar
            campaign={this.props.campaign}
          />
          <header className="main-page">
            <div className="container">
              <section className="overview container">
                <CampaignStats campaign={this.props.campaign} />
              </section>

            </div>
          </header>
        </div >);
    }

    return (
      <div>
        <CampaignNavbar
          campaign={this.props.campaign}
        />
        <div className="container campaign_main">
          <section className="overview container">
            <CampaignStats campaign={this.props.campaign} />
          </section>
          {campaignHandler}
          <Switch>
            <Route exact path="/campaigns/:campaign_slug/ores_plot" component={CampaignOresPlot} />
            <Route exact path="/campaigns/:campaign_slug/alerts" component={CampaignAlerts} />
          </Switch>
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
