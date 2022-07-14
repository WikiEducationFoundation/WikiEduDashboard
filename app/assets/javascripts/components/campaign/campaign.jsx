import { Route, Routes } from 'react-router-dom';
import withRouter from '../util/withRouter';
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
import WikidataOverviewStats from '../common/wikidata_overview_stats';

export const Campaign = createReactClass({
  displayName: 'Campaign',

  propTypes: {
    campaign: PropTypes.object.isRequired,
    match: PropTypes.object,
  },

  componentDidMount() {
    const campaignSlug = this.props.router.params.campaign_slug;
    return this.props.getCampaign(campaignSlug);
  },

  render() {
    if (this.props.campaign.loading) {
      return <div />;
    }

    let campaignHandler;
    if (window.location.href.match(/overview/)) {
      campaignHandler = (
        <div className="high-modal">
          <CampaignOverviewHandler {...this.props} />
        </div>
        );
    }

    return (
      <div>
        <CampaignNavbar
          campaign={this.props.campaign}
        />
        <div className="container campaign_main">
          <section className="overview container">
            <CampaignStats campaign={this.props.campaign} />
            {this.props.campaign.course_stats &&
            this.props.campaign.course_stats['www.wikidata.org'] &&
            <WikidataOverviewStats
              statistics={this.props.campaign.course_stats['www.wikidata.org']}
            />}
          </section>
          {campaignHandler}
          <Routes>
            <Route path="ores_plot" element={<CampaignOresPlot />} />
            <Route path="alerts" element={<CampaignAlerts />} />
          </Routes>
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
