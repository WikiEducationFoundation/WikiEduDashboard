import React from 'react';

import { connect } from 'react-redux';
import PropTypes from 'prop-types';
import createReactClass from 'create-react-class';
import AddAdminButton from './views/add_admin_button.jsx';
import AdminUserList from './admin_users_list.jsx';
import Notifications from '../common/notifications';
import { fetchAdminUsers } from '../../actions/settings_actions';

const SettingsHandler = createReactClass({
  propTypes: {
    fetchAdminUsers: PropTypes.func,
    adminUsers: PropTypes.arrayOf(
      PropTypes.shape({
        id: PropTypes.number,
        username: PropTypes.string.isRequired,
        real_name: PropTypes.string,
        permissions: PropTypes.number.isRequired,
      })
    ),
  },
  componentWillMount() {
    this.props.fetchAdminUsers();
  },

  render() {
    return (
      <div className="mt4 container">
        <Notifications />
        <h1 className="mx2" style={{ display: "inline-block", maring: 0 }}>All Admin Users</h1>
        <AddAdminButton />
        <AdminUserList adminUsers={this.props.adminUsers} />
      </div>

    );
  },
});

const mapStateToProps = state => ({
  adminUsers: state.settings.adminUsers,
});

const mapDispatchToProps = {
  fetchAdminUsers,
};

export default connect(mapStateToProps, mapDispatchToProps)(SettingsHandler);
