import { connect } from 'react-redux';
import { updateSalesforceCredentials } from '../../../actions/settings_actions';
import SalesforceCredentialsForm from '../views/salesforce_credentials_form';

const mapDispatchToProps = {
  updateSalesforceCredentials,
};

export default connect(null, mapDispatchToProps)(SalesforceCredentialsForm);
