// /* eslint no-undef: 2 */
import React from 'react';
import createReactClass from 'create-react-class';
import { withRouter } from 'react-router';
import { connect } from 'react-redux';
import PropTypes from 'prop-types';
import CampaignNavbar from '../common/campaign_navbar.jsx';
import { getCampaign } from '../../actions/campaign1_actions';


export const Campaign = createReactClass({
  displayName: 'Campaign',

  propTypes: {
    campaign: PropTypes.object.isRequired,
    match: PropTypes.object,
  },

  componentDidMount() {
    const campaignSlug = this.props.match.params.slug;
    // console.log(this.props.campaign);
    console.log(`coming from componentDidMount ${this.props.getCampaign(campaignSlug}`));
return this.props.getCampaign(campaignSlug);
  },

_campaignLinkParams() {
  return '/campaigns/slug';
},

render() {
  console.log(`from render ${this.props.campaign}`);
  return (
    <div className="container">
      {/* <h2>{this.props.campaign.slug}</h2> */}
      <CampaignNavbar
        campaign={this.props.campaign}
        campaignLink={this._campaignLinkParams}
      />
      <h1>Hello world!</h1>
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
