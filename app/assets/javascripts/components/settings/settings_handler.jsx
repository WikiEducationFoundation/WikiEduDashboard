import React from 'react';

import { connect } from 'react-redux';
import PropTypes from 'prop-types';
import createReactClass from 'create-react-class';
import AddAdminButton from './views/add_admin_button';
import AddSpecialUserButton from './views/add_special_user_button';
import AdminUserList from './admin_users_list';
import Notifications from '../common/notifications';
import { fetchAdminUsers, fetchSpecialUsers, fetchCourseCreationSettings, fetchDefaultCampaign } from '../../actions/settings_actions';
import SpecialUserList from './special_users_list';
import UpdateSalesforceCredentials from './views/update_salesforce_credentials';
import CourseCreationSettings from './course_creation_settings';
import DefaultCampaignSetting from './default_campaign_setting';
import UpdateImpactStats from './views/update_impact_stats';

export const SettingsHandler = createReactClass({
  propTypes: {
    fetchAdminUsers: PropTypes.func,
    fetchSpecialUsers: PropTypes.func,
    fetchDefaultCampaign: PropTypes.func,
    adminUsers: PropTypes.arrayOf(
      PropTypes.shape({
        id: PropTypes.number,
        username: PropTypes.string.isRequired,
        real_name: PropTypes.string,
        permissions: PropTypes.number.isRequired,
      })
    ),
    specialUsers: PropTypes.object,
    courseCreation: PropTypes.object,
    defaultCampaign: PropTypes.string
  },

  componentDidMount() {
    this.props.fetchAdminUsers();
    this.props.fetchSpecialUsers();
    this.props.fetchCourseCreationSettings();
    this.props.fetchDefaultCampaign();
  },

  render() {
    let otherSettings;
    if (Features.wikiEd) {
      otherSettings = (
        <React.Fragment>
          <h1 className="mx2 mt4">Other settings</h1>
          <hr />
          <h2 className="mx2">Impact Stats</h2>
          <UpdateImpactStats />
          <br /> <br />
          <h2 className="mx2">Salesforce</h2>
          <UpdateSalesforceCredentials />
          <br /> <br />
          <CourseCreationSettings settings={this.props.courseCreation}/>
          <br />
          <DefaultCampaignSetting defaultCampaign={this.props.defaultCampaign}/>
        </React.Fragment>
      );
    }
    return (
      <div id="settings" className="mt4 container">
        <Notifications />
        <h1 className="mx2">Users</h1>
        <hr />
        <h2 className="mx2">Admin Users</h2>
        <AddAdminButton />
        <AdminUserList adminUsers={this.props.adminUsers} />
        <h2 className="mx2">Special Users</h2>
        <AddSpecialUserButton />
        <SpecialUserList specialUsers={this.props.specialUsers} />
        {otherSettings}
      </div>

    );
  },
});

const mapStateToProps = state => ({
  adminUsers: state.settings.adminUsers,
  specialUsers: state.settings.specialUsers,
  courseCreation: state.settings.courseCreation,
  defaultCampaign: state.settings.defaultCampaign
});

const mapDispatchToProps = {
  fetchAdminUsers,
  fetchSpecialUsers,
  fetchCourseCreationSettings,
  fetchDefaultCampaign
};

export default connect(mapStateToProps, mapDispatchToProps)(SettingsHandler);
