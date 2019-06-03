import React from 'react';

import { connect } from 'react-redux';
import PropTypes from 'prop-types';
import createReactClass from 'create-react-class';
import AddAdminButton from './views/add_admin_button';
import AddSpecialUserButton from './views/add_special_user_button';
import AdminUserList from './admin_users_list';
import Notifications from '../common/notifications';
import { fetchAdminUsers, fetchSpecialUsers } from '../../actions/settings_actions';
import SpecialUserList from './special_users_list';
import UpdateSalesforceCredentials from './views/update_salesforce_credentials';

export const SettingsHandler = createReactClass({
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
  changeDefaultCampaign(e) {
    const isChecked = e.target.checked;
    console.log(this.props);
  },

  render() {
    let salesforce;
    if (Features.wikiEd) {
      salesforce = (
        <React.Fragment>
          <h1 className="mx2">Other Settings</h1>
          <hr />
          <h2 className="mx2">Salesforce</h2>
          <UpdateSalesforceCredentials />
        </React.Fragment>
      );
    }
    return (
      <div id="settings" className="mt4 container">
        <Notifications />
        <h1 className="mx2" style={{ display: 'inline-block', maring: 0 }}>Users</h1>
        <div className="campaign-checkbox">
          <label>Enable default campaign </label>
          <input type="checkbox" onChange={this.changeDefaultCampaign} />
        </div>
        <hr />
        <h2 className="mx2">Admin Users</h2>
        <AddAdminButton />
        <AdminUserList adminUsers={this.props.adminUsers} />
        <h2 className="mx2">Special Users</h2>
        <AddSpecialUserButton />
        <SpecialUserList specialUsers={this.props.specialUsers} />
        {salesforce}
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
