import React, { useEffect } from 'react';
import { connect } from 'react-redux';
import PropTypes from 'prop-types';
import AddAdminButton from './views/add_admin_button';
import AddSpecialUserButton from './views/add_special_user_button';
import AdminUserList from './admin_users_list';
import Notifications from '../common/notifications';
import {
  fetchAdminUsers,
  fetchSpecialUsers,
  fetchCourseCreationSettings,
  fetchDefaultCampaign,
  fetchFeaturedCampaigns,
} from '../../actions/settings_actions';
import SpecialUserList from './special_users_list';
import UpdateSalesforceCredentials from './views/update_salesforce_credentials';
import CourseCreationSettings from './course_creation_settings';
import DefaultCampaignSetting from './default_campaign_setting';
import UpdateImpactStats from './views/update_impact_stats';
import AddFeaturedCampaign from './views/add_featured_campaign';
import FeaturedCampaignsList from './featured_campaigns_list';
import SiteNoticeSetting from './site_notice_setting';

const SettingsHandler = ({
  adminUsers,
  specialUsers,
  courseCreation,
  defaultCampaign,
  featuredCampaigns,
}) => {
  useEffect(() => {
    fetchAdminUsers();
    fetchSpecialUsers();
    fetchCourseCreationSettings();
    fetchDefaultCampaign();
    fetchFeaturedCampaigns();
  }, [
    fetchAdminUsers,
    fetchSpecialUsers,
    fetchCourseCreationSettings,
    fetchDefaultCampaign,
    fetchFeaturedCampaigns,
  ]);

  return (
    <div id="settings" className="mt4 container">
      <Notifications />
      <SiteNoticeSetting />
      <br />
      <h1 className="mx2">{I18n.t('settings.categories.users')}</h1>
      <hr />
      <h2 className="mx2">{I18n.t('settings.categories.admin_users')}</h2>
      <AddAdminButton />
      <AdminUserList adminUsers={adminUsers} />
      <h2 className="mx2">{I18n.t('settings.categories.special_users')}</h2>
      <AddSpecialUserButton />
      <SpecialUserList specialUsers={specialUsers} />
      {Features.wikiEd && (
        <>
          <h1 className="mx2 mt4">{I18n.t('settings.categories.other_settings')}</h1>
          <hr />
          <h2 className="mx2">{I18n.t('settings.categories.impact_stats')}</h2>
          <UpdateImpactStats />
          <br /> <br />
          <h2 className="mx2">{I18n.t('settings.categories.salesforce')}</h2>
          <UpdateSalesforceCredentials />
          <br /> <br />
          <CourseCreationSettings settings={courseCreation} />
          <br /> <br />
          <h2 className="mx2">{I18n.t('settings.categories.featured_campaigns')}</h2>
          <AddFeaturedCampaign />
          <FeaturedCampaignsList featuredCampaigns={featuredCampaigns} />
          <br /> <br />
          <DefaultCampaignSetting defaultCampaign={defaultCampaign} />
        </>
      )}
    </div>
  );
};

SettingsHandler.propTypes = {
  fetchAdminUsers: PropTypes.func.isRequired,
  fetchSpecialUsers: PropTypes.func.isRequired,
  fetchCourseCreationSettings: PropTypes.func.isRequired,
  fetchDefaultCampaign: PropTypes.func.isRequired,
  fetchFeaturedCampaigns: PropTypes.func.isRequired,
  adminUsers: PropTypes.arrayOf(
    PropTypes.shape({
      id: PropTypes.number,
      username: PropTypes.string.isRequired,
      real_name: PropTypes.string,
      permissions: PropTypes.number.isRequired,
    })
  ).isRequired,
  specialUsers: PropTypes.object,
  courseCreation: PropTypes.object,
  defaultCampaign: PropTypes.string,
  featuredCampaigns: PropTypes.array,
};

const mapStateToProps = state => ({
  adminUsers: state.settings.adminUsers,
  specialUsers: state.settings.specialUsers,
  courseCreation: state.settings.courseCreation,
  defaultCampaign: state.settings.defaultCampaign,
  featuredCampaigns: state.settings.featuredCampaigns,
});

const mapDispatchToProps = {
  fetchAdminUsers,
  fetchSpecialUsers,
  fetchCourseCreationSettings,
  fetchDefaultCampaign,
  fetchFeaturedCampaigns,
};

export default connect(mapStateToProps, mapDispatchToProps)(SettingsHandler);
