const filterFeaturedCampaigns = (response_json, featured_campaigns) => {
    let campaigns = response_json.campaigns;
    const featured_campaigns_slugs = featured_campaigns.campaign_slugs;
    if (featured_campaigns_slugs.length > 0) {
        campaigns = campaigns.filter(campaign => featured_campaigns_slugs.includes(campaign.slug));
        return campaigns;
    }
    return campaigns;
};

export default filterFeaturedCampaigns;
