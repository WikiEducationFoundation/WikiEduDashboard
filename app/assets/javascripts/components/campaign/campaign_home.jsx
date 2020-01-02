import React from 'react';
import PropTypes from 'prop-types';
import CampaignStats from './campaign_stats.jsx';


const CampaignHome = (props) => {
  return (
    <div>
      <CampaignStats campaign={props.campaign} />
    </div>
  );
};

CampaignHome.propTypes = {
  campaign: PropTypes.object.isRequired,
  match: PropTypes.object,
};

CampaignHome.propTypes = {
  campaign: PropTypes.object.isRequired,
  match: PropTypes.object,
};

export default CampaignHome;





