import { connect } from 'react-redux';
import { upgradeAdmin } from '../../../actions/settings_actions';
import AddAdminForm from '../views/add_admin_form';

const mapStateToProps = state => ({
  submittingNewAdmin: state.settings.submittingNewAdmin,
});

const mapDispatchToProps = {
  upgradeAdmin,
};

export default connect(mapStateToProps, mapDispatchToProps)(AddAdminForm);
