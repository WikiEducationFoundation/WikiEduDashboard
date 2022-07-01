import I18n from 'i18n-js';
import React from 'react';
import { useSelector } from 'react-redux';
import { getCurrentUser } from '../../selectors';
import DetailedCampaignList from '../campaign/detailed_campaign_list';

const Explore = () => {
  const user = getCurrentUser(useSelector(state => state));
  return (
    <div id="campaigns">
      <DetailedCampaignList headerText={I18n.t('campaign.newest_campaigns')} newest/>
      <div className="campaigns-actions" >
        {user.admin && <a className="button dark" href="campaigns/new?create=true">{I18n.t('campaign.create_campaign')}</a>}
        <a href="/campaigns" className="button">
          {I18n.t('campaign.all_campaigns')} <span className="icon icon-rt_arrow" />
        </a>
      </div>
    </div>
  );
};

export default Explore;
