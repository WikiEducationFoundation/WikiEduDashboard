// /* eslint no-undef: 2 */
import React from 'react';
import createReactClass from 'create-react-class';
// import { Route, Switch } from 'react-router-dom';
import { withRouter } from 'react-router';
import { connect } from 'react-redux';
import PropTypes from 'prop-types';
import CampaignNavbar from '../common/campaign_navbar.jsx';
import { getCampaign } from '../../actions/campaign1_actions';
import CampaignHome from './campaign_home.jsx';


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
    const campaignSlug = this.props.match.params.slug;
    const campaign = this.props.campaign;
    if (!campaignSlug || !campaign || !campaign.home_wiki) {
      return <div />;
    }
    return (
      <div>
        <CampaignNavbar
          campaign={this.props.campaign}
        />
        <CampaignHome campaign={this.props.campaign} />
      </div>
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
