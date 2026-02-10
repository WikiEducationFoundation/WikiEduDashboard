import React, { useEffect } from 'react';
import { useDispatch, useSelector } from 'react-redux';
import PropTypes from 'prop-types';
import AddAdminButton from './views/add_admin_button';
import AddSpecialUserButton from './views/add_special_user_button';
import AdminUserList from './admin_users_list';
import Notifications from '../common/notifications';
import { fetchAdminUsers, fetchSpecialUsers, fetchCourseCreationSettings, fetchDefaultCampaign, fetchFeaturedCampaigns, fetchDisallowedUsers } from '../../actions/settings_actions';
import SpecialUserList from './special_users_list';
import UpdateSalesforceCredentials from './views/update_salesforce_credentials';
import CourseCreationSettings from './course_creation_settings';
import DefaultCampaignSetting from './default_campaign_setting';
import UpdateImpactStats from './views/update_impact_stats';
import AddFeaturedCampaign from './views/add_featured_campaign';
import FeaturedCampaignsList from './featured_campaigns_list';
import SiteNoticeSetting from './site_notice_setting';
import CelebrationBannerSetting from './celebration_banner_setting';
import AddDisallowedUserButton from './views/add_disallowed_user_button';
import DisallowedUsersList from './disallowed_users_list';

const SettingsHandler = () => {
  const dispatch = useDispatch();

  const adminUsers = useSelector(state => state.settings.adminUsers);
  const specialUsers = useSelector(state => state.settings.specialUsers);
  const courseCreation = useSelector(state => state.settings.courseCreation);
  const defaultCampaign = useSelector(state => state.settings.defaultCampaign);
  const featuredCampaigns = useSelector(state => state.settings.featuredCampaigns);
  const disallowedUsers = useSelector(state => state.settings.disallowedUsers);

  useEffect(() => {
    dispatch(fetchAdminUsers());
    dispatch(fetchSpecialUsers());
    dispatch(fetchCourseCreationSettings());
    dispatch(fetchDefaultCampaign());
    dispatch(fetchFeaturedCampaigns());
    dispatch(fetchDisallowedUsers());
  }, [dispatch]);

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
        <CourseCreationSettings settings={courseCreation}/>
        <br /> <br />
        <h2 className="mx2">{I18n.t('settings.categories.featured_campaigns')}</h2>
        <AddFeaturedCampaign />
        <FeaturedCampaignsList featuredCampaigns={featuredCampaigns} />
        <br /> <br />
        <DefaultCampaignSetting defaultCampaign={defaultCampaign}/>
      </React.Fragment>
    );
  }

  return (
    <div id="settings" className="mt4 container">
      <Notifications />
      <SiteNoticeSetting />
      <br />
      <CelebrationBannerSetting />
      <br />
      <h1 className="mx2">{I18n.t('settings.categories.users')}</h1>
      <hr />
      <h2 className="mx2">{I18n.t('settings.categories.admin_users')}</h2>
      <AddAdminButton />
      <AdminUserList adminUsers={adminUsers} />
      <h2 className="mx2">{I18n.t('settings.categories.special_users')}</h2>
      <AddSpecialUserButton />
      <SpecialUserList specialUsers={specialUsers} />
      <h2 className="mx2">{I18n.t('settings.disallowed_users.title')} <AddDisallowedUserButton /></h2>
      <DisallowedUsersList disallowedUsers={disallowedUsers} />
      {otherSettings}
    </div>
  );
};

SettingsHandler.propTypes = {
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
  featuredCampaigns: PropTypes.array,
  disallowedUsers: PropTypes.array
};

export default SettingsHandler;

