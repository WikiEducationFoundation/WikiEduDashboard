import React from 'react';

import { connect } from 'react-redux';
import PropTypes from 'prop-types';
import createReactClass from 'create-react-class';
import AddAdminButton from './views/add_admin_button';
import AddSpecialUserButton from './views/add_special_user_button';
import AdminUserList from './admin_users_list';
import Notifications from '../common/notifications';
import { fetchAdminUsers, fetchSpecialUsers, fetchCourseCreationSettings, fetchDefaultCampaign, fetchFeaturedCampaigns } from '../../actions/settings_actions';
import SpecialUserList from './special_users_list';
import UpdateSalesforceCredentials from './views/update_salesforce_credentials';
import CourseCreationSettings from './course_creation_settings';
import DefaultCampaignSetting from './default_campaign_setting';
import UpdateImpactStats from './views/update_impact_stats';
import AddFeaturedCampaign from './views/add_featured_campaign';
import FeaturedCampaignsList from './featured_campaigns_list';
import SiteNoticeSetting from './site_notice_setting';

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
    defaultCampaign: PropTypes.string,
    featuredCampaigns: PropTypes.array
  },

  componentDidMount() {
    this.props.fetchAdminUsers();
    this.props.fetchSpecialUsers();
    this.props.fetchCourseCreationSettings();
    this.props.fetchDefaultCampaign();
    this.props.fetchFeaturedCampaigns();
  },

  render() {
    let otherSettings;
    if (Features.wikiEd) {
      otherSettings = (
        <React.Fragment>
          <h1 className="mx2 mt4">{I18n.t('settings.categories.other_settings')}</h1>
          <hr />
          <h2 className="mx2">{I18n.t('settings.categories.impact_stats')}</h2>
          <UpdateImpactStats />
          <br /> <br />
          <h2 className="mx2">{I18n.t('settings.categories.salesforce')}</h2>
          <UpdateSalesforceCredentials />
          <br /> <br />
          <CourseCreationSettings settings={this.props.courseCreation}/>
          <br /> <br />
          <h2 className="mx2">{I18n.t('settings.categories.featured_campaigns')}</h2>
          <AddFeaturedCampaign />
          <FeaturedCampaignsList featuredCampaigns={this.props.featuredCampaigns} />
          <br /> <br />
          <DefaultCampaignSetting defaultCampaign={this.props.defaultCampaign}/>
        </React.Fragment>
      );
    }
    return (
      <div id="settings" className="mt4 container">
        <Notifications />
        <SiteNoticeSetting />
        <br />
        <h1 className="mx2">{I18n.t('settings.categories.users')}</h1>
        <hr />
        <h2 className="mx2">{I18n.t('settings.categories.admin_users')}</h2>        
        <AddAdminButton />
        <AdminUserList adminUsers={this.props.adminUsers} />
        <h2 className="mx2">{I18n.t('settings.categories.special_users')}</h2>
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
  defaultCampaign: state.settings.defaultCampaign,
  featuredCampaigns: state.settings.featuredCampaigns
});

const mapDispatchToProps = {
  fetchAdminUsers,
  fetchSpecialUsers,
  fetchCourseCreationSettings,
  fetchDefaultCampaign,
  fetchFeaturedCampaigns
};

export default connect(mapStateToProps, mapDispatchToProps)(SettingsHandler);
