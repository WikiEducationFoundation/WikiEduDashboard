import React from 'react';

import { connect } from 'react-redux';
import PropTypes from 'prop-types';
import createReactClass from 'create-react-class';
import AddAdminButton from './views/add_admin_button.jsx';
import AddSpecialUserButton from './views/add_special_user_button.jsx';
import AdminUserList from './admin_users_list.jsx';
import Notifications from '../common/notifications';
import { fetchAdminUsers, fetchSpecialUsers } from '../../actions/settings_actions';
import SpecialUserList from './special_users_list';

const SettingsHandler = createReactClass({
  propTypes: {
    fetchAdminUsers: PropTypes.func,
    fetchSpecialUsers: PropTypes.func,
    adminUsers: PropTypes.arrayOf(
      PropTypes.shape({
        id: PropTypes.number,
        username: PropTypes.string.isRequired,
        real_name: PropTypes.string,
        permissions: PropTypes.number.isRequired,
      })
    ),
    specialUsers: PropTypes.object
  },

  componentWillMount() {
    this.props.fetchAdminUsers();
    this.props.fetchSpecialUsers();
  },

  render() {
    return (
      <div className="mt4 container">
        <Notifications />
        <h1 className="mx2" style={{ display: 'inline-block', maring: 0 }}>Users</h1>
        <hr />
        <h2 className="mx2" style={{ display: 'inline-block', maring: 0 }}>Admin Users</h2>
        <AddAdminButton />
        <AdminUserList adminUsers={this.props.adminUsers} />
        <hr />
        <h2 className="mx2" style={{ display: 'inline-block', maring: 0 }}>Special Users</h2>
        <AddSpecialUserButton />
        <SpecialUserList specialUsers={this.props.specialUsers} />
      </div>

    );
  },
});

const mapStateToProps = state => ({
  adminUsers: state.settings.adminUsers,
  specialUsers: state.settings.specialUsers
});

const mapDispatchToProps = {
  fetchAdminUsers,
  fetchSpecialUsers
};

export default connect(mapStateToProps, mapDispatchToProps)(SettingsHandler);
