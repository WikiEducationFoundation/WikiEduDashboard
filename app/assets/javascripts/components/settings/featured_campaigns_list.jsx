import React from 'react';
import List from '../common/list.jsx';
import { ConnectedFeaturedCampaigns } from './containers/featured_campaigns_contrainer.jsx';

const FeaturedCampaignsList = ({ featuredCampaigns }) => {
  const elements = featuredCampaigns?.map((campaign, index) => {
    return <ConnectedFeaturedCampaigns
      slug={campaign.slug}
      title={campaign.title}
      key={index}
    />;
  });

  const keys = {
    campaign_title: {
      label: 'Campaign Title',
      desktop_only: false,
    },
    campaign_slug: {
      label: 'Campaign Slug',
      desktop_only: false,
    }
  };
  return (
    <div>
      <List
        elements={elements}
        keys={keys}
        table_key="featured-campaigns-list"
        none_message={I18n.t('settings.featured_campaigns.no_featured_campaigns')}
      />
    </div>
  );
};

export default FeaturedCampaignsList;
