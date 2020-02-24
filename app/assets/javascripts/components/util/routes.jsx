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

const routes = (

  <Switch>
    <Route path="/onboarding" component={Onboarding} />
    <Route path="/recent-activity" component={RecentActivityHandler} />
    <Route path="/courses/:course_school/:course_title" component={Course} />
    <Route path="/course_creator" component={ConnectedCourseCreator} />
    <Route path="/users/:username" component={UserProfile} />
    <Route path="/alerts_list" component={AdminAlerts} />
    <Route path="/settings" component={SettingsHandler} />
    <Route path="/article_finder" component={ArticleFinder} />
    <Route path="/training" component={TrainingApp} />
    <Route exact path="/tickets/dashboard" component={TicketsHandler} />
    <Route exact path="/tickets/dashboard/:id" component={TicketShowHandler} />
    <Route path="/campaigns/:campaign_slug" component={Campaign} />
  </Switch>
);

export default routes;
