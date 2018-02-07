import React from 'react';
import createReactClass from 'create-react-class';
import PropTypes from 'prop-types';
import { connect } from 'react-redux';
import Select from 'react-select';

import { getAvailableCampaigns } from '../../selectors';

import PopoverExpandable from '../high_order/popover_expandable.jsx';
import Conditional from '../high_order/conditional.jsx';
import CourseUtils from '../../utils/course_utils.js';

import { removeCampaign, fetchAllCampaigns, addCampaign } from '../../actions/campaign_actions';

const CampaignButton = createReactClass({
  displayName: 'CampaignButton',

  getKey() {
    return `add_campaign`;
  },

  PropTypes: {
    campaigns: PropTypes.array,
    inline: PropTypes.boolean,
    open: PropTypes.func,
    is_open: PropTypes.bool,
    all_campaigns: PropTypes.array
  },

  stop(e) {
    return e.stopPropagation();
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
    let campaignList;
    if (this.props.editable) {
      campaignList = this.props.campaigns.map(campaign => {
        const removeButton = (
          <button className="button border plus" onClick={this.removeCampaign.bind(this, campaign.title)}>-</button>
        );
        return (
          <tr key={`${campaign.id}_campaign`}>
            <td>{campaign.title}{removeButton}</td>
          </tr>
        );
      });
    } else {
      const lastIndex = this.props.campaigns.length - 1;
      const campaigns = (this.props.campaigns.length > 0 ?
        _.map(this.props.campaigns, (campaign, index) => {
          let comma = '';
          const url = `/campaigns/${campaign.slug}/overview`;
          if (index !== lastIndex) { comma = ', '; }
          return <span key={campaign.slug}><a href={url}>{campaign.title}</a>{comma}</span>;
        })
      : I18n.t('courses.none'));
      campaignList = <span> {campaigns}</span>;
    }

    const campaignOptions = this.props.allCampaigns.map(campaign => {
      return { label: campaign, value: campaign };
    });

    let campaignSelect;
    if (this.props.allCampaigns.length > 0) {
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


    return (
      <div className="container" onClick={this.stop}>
        <strong>{CourseUtils.i18n('campaigns', this.props.course.string_prefix)}</strong>
        {campaignList}
        {campaignSelect}
      </div>
    );
  }

});

const mapStateToProps = state => ({
  allCampaigns: getAvailableCampaigns(state),
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
