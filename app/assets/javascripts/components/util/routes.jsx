import React from 'react';
import { Route, Switch } from 'react-router-dom';

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
  <Switch>
    <Route path="/onboarding" >
      <Onboarding />
    </Route>
    <Route path="/recent-activity" >
      <RecentActivityHandler />
    </Route>
    <Route path="/courses/:course_school/:course_title" >
      <Course />
    </Route>
    <Route path="/course_creator" >
      <ConnectedCourseCreator />
    </Route>
    <Route path="/users/:username" >
      <UserProfile />
    </Route>
    <Route path="/alerts_list" >
      <AdminAlerts />
    </Route>
    <Route path="/settings" >
      <SettingsHandler />
    </Route>
    <Route path="/article_finder" >
      <ArticleFinder />
    </Route>
    <Route path="/training" >
      <TrainingApp />
    </Route>
    <Route exact path="/tickets/dashboard" >
      <TicketsHandler />
    </Route>
    <Route exact path="/tickets/dashboard/:id" >
      <TicketShowHandler />
    </Route>
    <Route path="/campaigns/:campaign_slug" >
      <Campaign />
    </Route>
    <Route path="/tagged_courses/:tag/alerts" >
      <TaggedCourseAlerts />
    </Route>
  </Switch>
);

export default routes;
