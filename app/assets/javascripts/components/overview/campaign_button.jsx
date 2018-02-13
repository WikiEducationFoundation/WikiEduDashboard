import React from 'react';
import createReactClass from 'create-react-class';
import PropTypes from 'prop-types';
import { connect } from 'react-redux';
import Select from 'react-select';
import _ from 'lodash';

import { getAvailableCampaigns } from '../../selectors';

import PopoverExpandable from '../high_order/popover_expandable.jsx';
import Conditional from '../high_order/conditional.jsx';
import CourseUtils from '../../utils/course_utils.js';

import { removeCampaign, fetchAllCampaigns, addCampaign } from '../../actions/campaign_actions';


const CampaignButton = createReactClass({
  displayName: 'CampaignButton',

  componentDidMount() {
    return this.props.fetchAllCampaigns();
  },

  getKey() {
    return `add_campaign`;
  },

  PropTypes: {
    campaigns: PropTypes.array,
    availableCampaigns: PropTypes.array,
    fetchAllCampaigns: PropTypes.func
  },

  handleChangeCampaign(val) {
    return this.props.addCampaign(this.props.course_id, val.value);
  },

  removeCampaign(campaignId) {
    this.props.removeCampaign(this.props.course_id, campaignId);
  },

  addCampaign(campaignId) {
    this.props.addCampaign(this.props.course_id, campaignId);
  },

  render() {
    let campaignClass = "campaigns container close";
    const lastIndex = this.props.campaigns.length - 1;
    let campaigns = (this.props.campaigns.length > 0 ?
      _.map(this.props.campaigns, (campaign, index) => {
        let comma = '';
        const url = `/campaigns/${campaign.slug}/overview`;
        if (index !== lastIndex) { comma = ', '; }
        return <span key={campaign.slug}><a href={url}>{campaign.title}</a>{comma}</span>;
      })
    : I18n.t('courses.none'));

    // In editable mode we'll show a list of campaigns and a remove button plus a selector to add new campaigns
    if (this.props.editable) {
      campaignClass = "campaigns container open";
      const campaignList = this.props.campaigns.map(campaign => {
        const removeButton = (
          <button className="button border plus" onClick={this.removeCampaign.bind(this, campaign.title)}>-</button>
        );
        return (
          <tr key={`${campaign.id}_campaign`}>
            <td>{campaign.title}{removeButton}</td>
          </tr>
        );
      });

      let campaignSelect;
      if (this.props.availableCampaigns.length > 0) {
        const campaignOptions = this.props.availableCampaigns.map(campaign => {
          return { label: campaign, value: campaign };
        });
        campaignSelect = (
          <Select
            ref="campaignSelect"
            name="campaign"
            placeholder="Campaign"
            onChange={this.handleChangeCampaign}
            options={campaignOptions}
          />
        );
      }

      campaigns = (
        <div className="form-group">
          <table>
            <tbody>
              {campaignList}
            </tbody>
          </table>
          {campaignSelect}
        </div>
      );
    }

    return (
      <div key="campaigns" className={campaignClass}>
        <strong>{CourseUtils.i18n('campaigns', this.props.course.string_prefix)}</strong>
        <span> {campaigns}</span>
      </div>
    );
  }

});

const mapStateToProps = state => ({
  availableCampaigns: getAvailableCampaigns(state),
  campaigns: state.campaigns.campaigns
});

const mapDispatchToProps = {
  removeCampaign,
  addCampaign,
  fetchAllCampaigns

};

export default connect(mapStateToProps, mapDispatchToProps)(
  Conditional(PopoverExpandable(CampaignButton))
);
