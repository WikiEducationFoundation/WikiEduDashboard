import React from 'react';
import PropTypes from 'prop-types';

const CampaignStats = (props) => {
  return (
    <div className="container campaign_main">
      <div className="overview container">
        <div className="stat-display">
          <div className="stat-display__stat">
            <div className="stat-display__value">{props.campaign.courses_count}</div>
            <small>Programs</small>
          </div>
          <div className="stat-display__stat tootltip-trigger">
            <div className="stat-display__value">0
              <img alt="tooltip default logo" src="/assets/images/info.svg" />
            </div>
            <small>Editors</small>
          </div>
        </div>
      </div>
    </div>
  );
};

CampaignStats.propTypes = {
  campaign: PropTypes.object.isRequired,
  match: PropTypes.object,
};

export default CampaignStats;

