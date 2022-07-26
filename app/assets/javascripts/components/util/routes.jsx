import React, { Suspense, lazy } from 'react';
import { Route, Routes } from 'react-router-dom';
import Loading from '../common/loading.jsx';

const Course = lazy(() => import('../course/course.jsx'));
const Onboarding = lazy(() => import('../onboarding/index.jsx'));
const ConnectedCourseCreator = lazy(() => import('../course_creator/course_creator.jsx'));
const ArticleFinder = lazy(() => import('../article_finder/article_finder.jsx'));
const AdminAlerts = lazy(() => import('../alerts/admin_alerts.jsx'));
const RecentActivityHandler = lazy(() => import('../activity/recent_activity_handler.jsx'));
const UserProfile = lazy(() => import('../user_profiles/user_profile.jsx'));
const SettingsHandler = lazy(() => import('../settings/settings_handler.jsx'));
const TicketsHandler = lazy(() => import('../tickets/tickets_handler.jsx'));
const TicketShowHandler = lazy(() => import('../tickets/ticket_show_handler.jsx'));
const TaggedCourseAlerts = lazy(() => import('../alerts/tagged_course_alerts.jsx'));
const CampaignsHandler = lazy(() => import('../campaign/campaigns_handler.jsx'));
const DetailedCampaignList = lazy(() => import('../campaign/detailed_campaign_list'));
const Explore = lazy(() => import('../explore/explore.jsx'));
const TrainingApp = lazy(() => import('../../training/components/training_app.jsx'));
const ActiveCoursesHandler = lazy(() => import('../active_courses/active_courses_handler.jsx'));
const CoursesByWikiHandler = lazy(() => import('../courses_by_wiki/courses_by_wiki_handler.jsx'));

const routes = (
  <Suspense fallback={<Loading />}>
    <Routes>
      <Route path="/onboarding/*" element={<Onboarding />} />
      <Route path="/recent-activity/*" element={<RecentActivityHandler />} />
      <Route path="/courses/:course_school/:course_title/*" element={<Course />} />
      <Route path="/course_creator" element={<ConnectedCourseCreator />} />
      <Route path="/users/:username" element={<UserProfile />} />
      <Route path="/alerts_list" element={<AdminAlerts />} />
      <Route path="/settings" element={<SettingsHandler />} />
      <Route path="/article_finder" element={<ArticleFinder />} />
      <Route path="/training/*" element={<TrainingApp />} />
      <Route path="/tickets/dashboard" element={<TicketsHandler />} />
      <Route path="/tickets/dashboard/:id" element={<TicketShowHandler />} />
      <Route path="/campaigns/*" element={<CampaignsHandler />} />
      <Route path="/tagged_courses/:tag/alerts" element={<TaggedCourseAlerts />} />
      <Route index element={<DetailedCampaignList headerText={I18n.t('campaign.campaigns')} userOnly={true}/>} />
      <Route path="/dashboard" element={<DetailedCampaignList headerText={I18n.t('campaign.campaigns')} userOnly={true}/>} />
      <Route path="/explore" element={<Explore dashboardTitle={window.dashboardTitle}/>} />
      <Route path="/active_courses" element={<ActiveCoursesHandler dashboardTitle={window.dashboardTitle}/>}/>
      <Route path="/courses_by_wiki/:wiki_url" element={<CoursesByWikiHandler />}/>

      {/* this prevents the "route not found" warning for pages which are server rendered */}
      <Route path="*" element={<div style={{ display: 'none' }}/>} />
    </Routes>
  </Suspense>
);

export default routes;
