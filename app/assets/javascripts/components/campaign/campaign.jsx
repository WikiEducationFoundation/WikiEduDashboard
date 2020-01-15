// /* eslint no-undef: 2 */
import { Route, Switch } from 'react-router-dom';
import { withRouter } from 'react-router';
import React from 'react';
import createReactClass from 'create-react-class';
import { connect } from 'react-redux';
import PropTypes from 'prop-types';
import CampaignNavbar from '../common/campaign_navbar.jsx';
import { getCampaign } from '../../actions/campaign1_actions';
import CampaignHome from './campaign_home.jsx';
import CampaignAlerts from '../alerts/campaign_alerts.jsx';
import CampaignOresPlot from './campaign_ores_plot.jsx';
// import CampaignStats from './campaign_stats.jsx';
import CampaignPrograms from './campaign_programs.jsx';
import CampaignArticles from './campaign_articles.jsx';
import CampaignEditors from './campaign_editors.jsx';


export const Campaign = createReactClass({
  displayName: 'Campaign',

  propTypes: {
    campaign: PropTypes.object.isRequired,
    match: PropTypes.object,
  },

  componentDidMount() {
    const campaignSlug = this.props.match.params.slug;
    console.log(`campaignSlug:${campaignSlug}`);
    return this.props.getCampaign(campaignSlug);
  },

  render() {
    if (!this.props.campaign.uploads_in_use_count) {
      return <div />;
    }
    return (
      <div>
        <CampaignNavbar
          campaign={this.props.campaign}
        />
        <Switch>
          {/* <Route exact path="/campaigns/:slug/overview" render={() => <CampaignStats {...this.props.campaign} />} /> */}
          <Route exact path="/campaigns/:slug/programs" component={CampaignPrograms} />
          <Route exact path="/campaigns/:slug/articles" component={CampaignArticles} />
          <Route exact path="/campaigns/:slug/users" component={CampaignEditors} />
          <Route exact path="/campaigns/:slug/ores_plot" component={CampaignOresPlot} />
          <Route exact path="/campaigns/:slug/alerts" component={CampaignAlerts} />
        </Switch>
        <CampaignHome campaign={this.props.campaign} />
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
