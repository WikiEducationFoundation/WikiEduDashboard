import React from 'react';
import { fetchAdminUsers } from '../../actions/settings_actions';
import { connect } from 'react-redux';
import AdminUserList from './admin_users_list.jsx';
import AddAdminButton from './views/add_admin_button.jsx';
import Notifications from '../common/notifications';

class SettingsHandler extends React.Component {
  constructor() {
    super();
    this.render = this.render.bind(this);
    this.componentWillMount = this.componentWillMount.bind(this);
  }

  componentWillMount() {
    this.props.fetchAdminUsers();
  }

  render() {
    return (
      <div className="mt4 ml2">
        <Notifications />
        <h1 className="mx2" style={{ display: "inline-block", maring: 0 }}>All Admin Users</h1>
        <AddAdminButton />
        <AdminUserList adminUsers={this.props.adminUsers} />
      </div>

    );
  }
}

const mapStateToProps = state => ({
  adminUsers: state.settings.adminUsers,
});

const mapDispatchToProps = {
  fetchAdminUsers,
};

export default connect(mapStateToProps, mapDispatchToProps)(SettingsHandler);
