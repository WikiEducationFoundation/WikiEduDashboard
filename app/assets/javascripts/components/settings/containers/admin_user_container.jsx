import { connect } from 'react-redux';
import { downgradeAdmin } from '../../../actions/settings_actions';
import AdminUser from '../views/admin_user';

const mapStateToProps = state => ({
  revokingAdmin: state.settings.revokingAdmin,
});

const mapDispatchToProps = {
  downgradeAdmin,
};

export default connect(mapStateToProps, mapDispatchToProps)(AdminUser);
