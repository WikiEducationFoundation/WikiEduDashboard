const filterFeaturedCampaigns = (response_data, featured_campaigns) => {
  const featuredCampaignSlugs = featured_campaigns.map(campaign => campaign.slug);

  if (featuredCampaignSlugs.length > 0) {
    return response_data.campaigns.filter(campaign => featuredCampaignSlugs.includes(campaign.slug));
  }
  return response_data.campaigns;
};

export default filterFeaturedCampaigns;
