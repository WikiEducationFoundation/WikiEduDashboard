import React from 'react';
import { Route, Routes } from 'react-router-dom';

import Course from '../course/course.jsx';
import Onboarding from '../onboarding/index.jsx';
import { ConnectedCourseCreator } from '../course_creator/course_creator.jsx';
import ArticleFinder from '../article_finder/article_finder.jsx';
import AdminAlerts from '../alerts/admin_alerts.jsx';
import RecentActivityHandler from '../activity/recent_activity_handler.jsx';
import TrainingApp from '../../training/components/training_app.jsx';
import UserProfile from '../user_profiles/user_profile.jsx';
import SettingsHandler from '../settings/settings_handler.jsx';
import TicketsHandler from '../tickets/tickets_handler.jsx';
import TicketShowHandler from '../tickets/ticket_show_handler.jsx';
import Campaign from '../campaign/campaign.jsx';
import TaggedCourseAlerts from '../alerts/tagged_course_alerts.jsx';

const routes = (
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
    <Route path="/campaigns/:campaign_slug/*" element={<Campaign />} />
    <Route path="/tagged_courses/:tag/alerts" element={<TaggedCourseAlerts />} />
  </Routes>
);

export default routes;
