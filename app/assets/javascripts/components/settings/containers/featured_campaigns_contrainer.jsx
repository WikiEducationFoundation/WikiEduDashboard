import { connect } from 'react-redux';
import { addFeaturedCampaign, removeFeaturedCampaign } from '../../../actions/settings_actions';
import FeaturedCampaignForm from '../views/update_featured_campaign_form';
import FeaturedCampaign from '../views/featured_campaign';

const mapDispatchToProps = {
  addFeaturedCampaign,
  removeFeaturedCampaign
};

export const ConnectedFeaturedCampaignForm = connect(null, mapDispatchToProps)(FeaturedCampaignForm);
export const ConnectedFeaturedCampaigns = connect(null, mapDispatchToProps)(FeaturedCampaign);
