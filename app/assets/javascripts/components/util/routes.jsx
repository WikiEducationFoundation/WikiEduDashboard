import React from 'react';
import { Route, Switch } from 'react-router-dom';

import Course from '../course/course.jsx';
import Onboarding from '../onboarding/index.jsx';
import { ConnectedCourseCreator } from '../course_creator/course_creator.jsx';
import ArticleFinder from '../article_finder/article_finder.jsx';
import AlertsHandler from '../alerts/alerts_handler.jsx';
import CampaignOverviewHandler from '../campaign/campaign_overview_handler.jsx';
import CampaignOresPlot from '../campaign/campaign_ores_plot.jsx';
import RecentActivityHandler from '../activity/recent_activity_handler.jsx';
import TrainingApp from '../../training/components/training_app.jsx';
import UserProfile from '../user_profiles/user_profile.jsx';
import SettingsHandler from '../settings/settings_handler.jsx';
import TicketsHandler from '../tickets/tickets_handler.jsx';
import TicketShowHandler from '../tickets/ticket_show_handler.jsx';

const routes = (
  <Switch>
    <Route path="/onboarding" component={Onboarding} />
    <Route path="/recent-activity" component={RecentActivityHandler} />
    <Route path="/courses/:course_school/:course_title" component={Course} />
    <Route path="/course_creator" component={ConnectedCourseCreator} />
    <Route path="/users/:username" component={UserProfile} />
    <Route path="/campaigns/:campaign_slug/overview" component={CampaignOverviewHandler} />
    <Route path="/campaigns/:campaign_slug/alerts" component={AlertsHandler} />
    <Route path="/campaigns/:campaign_slug/ores_plot" component={CampaignOresPlot} />
    <Route path="/settings" component={SettingsHandler} />
    <Route path="/article_finder" component={ArticleFinder} />
    <Route path="/training" component={TrainingApp} />
    <Route exact path="/tickets/dashboard" component={TicketsHandler} />
    <Route exact path="/tickets/dashboard/:id" component={TicketShowHandler} />
  </Switch>
);

export default routes;
