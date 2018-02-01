import React from 'react';
import PropTypes from 'prop-types';
import { connect } from 'react-redux';
import PopoverExpandable from '../high_order/popover_expandable.jsx';
//import CampaignStore from '../../stores/campaign_store.js';

//const campaignIsNew = campaign => CampaignStore.getFiltered({ title: campaign }).length === 0;

const CampaignButton = ({ campaigns }) => {
  const campaignList = campaigns.map(campaign => {
    const removeButton = (
      <button className="button border plus" >-</button>
    );
    return (
      <tr key={`${campaign.id}_campaign`}>
        <td>{campaign.title}{removeButton}</td>
      </tr>
    );
  });
  return (
    <div>{campaignList}</div>
  );
};

CampaignButton.propTypes = {
  campaigns: PropTypes.array
};


const mapDispatchToProps = {

}

export default connect(null, mapDispatchToProps)(
  PopoverExpandable(CampaignButton)
);
