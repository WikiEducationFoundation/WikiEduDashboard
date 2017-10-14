import React from 'react';
import PropTypes from 'prop-types';
import PopoverButton from '../high_order/popover_button.jsx';
import CampaignStore from '../../stores/campaign_store.js';

const campaignIsNew = campaign => CampaignStore.getFiltered({ title: campaign }).length === 0;

const campaigns = (props, remove) =>
  props.campaigns.map(campaign => {
    const removeButton = (
      <button className="button border plus" onClick={remove.bind(null, campaign.id)}>-</button>
    );
    return (
      <tr key={`${campaign.id}_campaign`}>
        <td>{campaign.title}{removeButton}</td>
      </tr>
    );
  })
;

campaigns.propTypes = {
  campaigns: PropTypes.array
};

export default PopoverButton('campaign', 'title', CampaignStore, campaignIsNew, campaigns, true);
