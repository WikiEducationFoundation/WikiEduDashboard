// /* eslint no-undef: 2 */
import { Route, NavLink, Switch } from 'react-router-dom';
// import { withRouter } from 'react-router';
import React from 'react';
import createReactClass from 'create-react-class';
import { connect } from 'react-redux';
import PropTypes from 'prop-types';
import CampaignNavbar from '../common/campaign_navbar.jsx';
import { getCampaign } from '../../actions/campaign1_actions';
import CampaignHome from './campaign_home.jsx';
import Alert from '../alerts/alert.jsx';


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
        <Switch>
          <CampaignNavbar
            campaign={this.props.campaign}
          />
          <Route path="/campaigns/miscellanea/alerts" component={Alert} />
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

export default connect(mapStateToProps, mapDispatchToProps)(Campaign);
// export default withRouter(connect(mapStateToProps, mapDispatchToProps)(Campaign));






