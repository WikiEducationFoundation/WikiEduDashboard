import React from 'react';
import createReactClass from 'create-react-class';
import PropTypes from 'prop-types';
import { connect } from 'react-redux';

import Popover from '../common/popover.jsx';
import PopoverExpandable from '../high_order/popover_expandable.jsx';
import Conditional from '../high_order/conditional.jsx';

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

  removeCampaign(campaignId) {
    this.props.removeCampaign(this.props.course_id, campaignId);
  },

  addCampaign(campaignId) {
    this.props.addCampaign(this.props.course_id, campaignId);
  },

  render() {
    const editRows = [];
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

    const allCampaigns = this.props.allCampaigns.map(campaign => {
      const addButton = (
        <button className="button border plus" onClick={this.addCampaign.bind(this, campaign)}>+</button>
      );
    return (
      <tr key={`${campaign}`}>
        <td>{campaign}{addButton}</td>
      </tr>
      );
    });

    let buttonClass = 'button';
    buttonClass += this.props.inline ? ' border plus' : ' dark';
    const buttonText = this.props.inline ? '+' : I18n.t('campaign.campaigns');
    const button = <button className={buttonClass} onClick={this.props.open}>{buttonText}</button>;
    return (
      <div className="pop__container" onClick={this.stop}>
        {campaignList}
        {button}
        <Popover
          is_open={this.props.is_open}
          edit_row={editRows}
          rows={allCampaigns}
        />
      </div>
    );
  }

});

const mapStateToProps = state => ({
  allCampaigns: state.campaigns.all_campaigns
});

const mapDispatchToProps = {
  removeCampaign,
  addCampaign,
  fetchAllCampaigns

};

export default connect(mapStateToProps, mapDispatchToProps)(
  Conditional(PopoverExpandable(CampaignButton))
);
