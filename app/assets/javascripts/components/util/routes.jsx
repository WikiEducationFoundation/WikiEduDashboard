import React, { Suspense, lazy, useEffect } from 'react';
import { useSelector, useDispatch } from 'react-redux';
import { Route, Routes, useLocation } from 'react-router-dom';
import Loading from '../common/loading.jsx';
import { refreshData } from './refresh.js';

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

const routes = () => {
  const location = useLocation();
  const dispatch = useDispatch();
  const refreshArgs = {
    lastUserRequestTimestamp: useSelector(state => state.users.lastRequestTimestamp),
    courseSlug: useSelector(state => state.course.slug),
    articlesLimit: useSelector(state => state.articles.limit),
    lastRequestArticleTimestamp: useSelector(state => state.articles.lastRequestTimestamp),
    lastRequestAssignmentTimestamp: useSelector(state => state.assignments.lastRequestTimestamp)
  };


  // this is called whenever the route changes
  // it ensures that the user isn't displayed stale/outdated data for a route
  // they previously visited(and thus had already loaded the data for in the Redux store)
  // this fires the refreshData function, which does a series of URL checks and checks to see if
  // the data is stale, and if so, refresh it by triggering the appropriate Redux action
  // see refresh.js for more details on how this works

  // the reason this exists here rather than in the individual components is to make the
  // entire thing more centralized and easier to maintain. Besides, the fact that the
  // this component deals with just the routes means that unnecessary re-renders are avoided
  useEffect(() => {
    refreshData(location, refreshArgs, dispatch);
  }, [location.pathname]);

  return (
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
};

export default routes;
