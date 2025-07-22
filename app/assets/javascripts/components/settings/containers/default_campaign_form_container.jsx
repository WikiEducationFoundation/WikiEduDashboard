import { connect } from 'react-redux';
import { updateDefaultCampaign } from '../../../actions/settings_actions';
import DefaultCampaignForm from '../views/default_campaign_form.jsx';

const mapDispatchToProps = {
  updateDefaultCampaign,
};

export default connect(null, mapDispatchToProps)(DefaultCampaignForm);
