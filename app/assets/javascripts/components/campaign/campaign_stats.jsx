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
            <div className="stat-display__value">
              {props.campaign.editors}
            </div>
            <small>Editors</small>
          </div>
          <div className="stat-display__stat">
            <div className="stat-display__value">
              {props.campaign.word_count}
            </div>
            <small>Words Added</small>
          </div>
          <div className="stat-display__stat tooltip-trigger">
            <div className="stat-display__value">
              {props.campaign.references_count}
              <img alt="tooltip default logo" src="/assets/images/info.svg" />
            </div>
            <small>References Added</small>
          </div>
          <div className="stat-display__stat">
            <div className="stat-display__value">
              {props.campaign.article_views}
            </div>
            <small>Article Views</small>
          </div>
          <div className="stat-display__stat">
            <div className="stat-display__value">
              {props.campaign.article_count}
            </div>
            <small>Articles Edited</small>
          </div>
          <div className="stat-display__stat">
            <div className="stat-display__value">
              {props.campaign.articles_created}
            </div>
            <small>Articles Created</small>
          </div>
          <div className="stat-display__stat tooltip-trigger">
            <div className="stat-display__value">
              {props.campaign.upload_count}
              <img alt="tooltip default logo" src="/assets/images/info.svg" />
            </div>
            <small>Commons Uploads</small>
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

