import React from 'react';
import ReactDOM from 'react-dom';
import { Router, Route, IndexRoute, browserHistory, IndexRedirect } from 'react-router';

import { Provider } from 'react-redux';
import { createStore, applyMiddleware, compose } from 'redux';
import thunk from 'redux-thunk';
import reducer from '../reducers';

import App from '../components/app.jsx';
import Course from '../components/course.jsx';
import Onboarding from '../components/onboarding/index.jsx';
import OnboardingIntro from '../components/onboarding/intro.jsx';
import OnboardingForm from '../components/onboarding/form.jsx';
import OnboardingSupplementary from '../components/onboarding/supplementary.jsx';
import OnboardingPermissions from '../components/onboarding/permissions.jsx';
import OnboardingFinished from '../components/onboarding/finished.jsx';
import Wizard from '../components/wizard/wizard.jsx';
import Meetings from '../components/timeline/meetings.jsx';
import { ConnectedCourseCreator } from '../components/course_creator/course_creator.jsx';
import OverviewHandler from '../components/overview/overview_handler.jsx';
import TimelineHandler from '../components/timeline/timeline_handler.jsx';
import RevisionsHandler from '../components/revisions/revisions_handler.jsx';
import StudentsHandler from '../components/students/students_handler.jsx';
import ArticlesHandler from '../components/articles/articles_handler.jsx';
import UploadsHandler from '../components/uploads/uploads_handler.jsx';
import AlertsHandler from '../components/alerts/alerts_handler.jsx';
import ArticleFinder from '../components/article_finder/article_finder.jsx';
import RecentActivityHandler from '../components/activity/recent_activity_handler.jsx';
import DidYouKnowHandler from '../components/activity/did_you_know_handler.jsx';
import PlagiarismHandler from '../components/activity/plagiarism_handler.jsx';
import RecentEditsHandler from '../components/activity/recent_edits_handler.jsx';
import RecentUploadsHandler from '../components/activity/recent_uploads_handler.jsx';

import TrainingApp from '../training/components/training_app.jsx';
import TrainingModuleHandler from '../training/components/training_module_handler.jsx';
import TrainingSlideHandler from '../training/components/training_slide_handler.jsx';

import RocketChat from '../components/common/rocket_chat.jsx';

import UserProfile from '../components/user_profiles/user_profile.jsx';
import SettingsHandler from '../components/settings/settings_handler.jsx';
import Nav from '../components/nav.jsx';

// The navbar is its own React element, independent of the
// main React Router-based component tree.
// `nav_root` is present throughout the app, via the Rails view layouts.
const navBar = document.getElementById('nav_root');
if (navBar) {
  ReactDOM.render((<Nav />), navBar);
}

// Handle scroll position for back button, hashes, and normal links
browserHistory.listen(location => {
  setTimeout(() => {
    if (location.action === 'POP') {
      return;
    }
    const hash = window.location.hash;
    if (hash) {
      const element = document.querySelector(hash);
      if (element) {
        element.scrollIntoView({
          block: 'start',
          behavior: 'smooth'
        });
      }
    } else {
      window.scrollTo(0, 0);
    }
  });
});

const routes = (
  <Route path="/" component={App}>
    <Route path="onboarding" component={Onboarding}>
      <IndexRoute component={OnboardingIntro} />
      <Route path="form" component={OnboardingForm} />
      <Route path="supplementary" component={OnboardingSupplementary} />
      <Route path="permissions" component={OnboardingPermissions} />
      <Route path="finish" component={OnboardingFinished} />
    </Route>
    <Route path="recent-activity" component={RecentActivityHandler}>
      <IndexRedirect to="dyk" />
      <Route path="dyk" component={DidYouKnowHandler} />
      <Route path="plagiarism" component={PlagiarismHandler} />
      <Route path="recent-edits" component={RecentEditsHandler} />
      <Route path="recent-uploads" component={RecentUploadsHandler} />
    </Route>
    <Route path="courses">
      <Route path=":course_school/:course_title" component={Course}>
        <IndexRoute component={OverviewHandler} />
        <Route path="home" component={OverviewHandler} />
        {/* The overview route path should not be removed in order to preserve the default url */}
        <Route path="overview" component={OverviewHandler} />
        <Route path="timeline" component={TimelineHandler}>
          <Route path="wizard" component={Wizard} />
          <Route path="dates" component={Meetings} />
        </Route>
        <Route path="activity" component={RevisionsHandler} />
        <Route path="students" component={StudentsHandler} />
        <Route path="articles" component={ArticlesHandler} />
        <Route path="uploads" component={UploadsHandler} />
        <Route path="chat" component={RocketChat} />
        <Route path="article_finder" component={ArticleFinder} />
      </Route>
    </Route>
    <Route path="course_creator" component={ConnectedCourseCreator} />
    <Route path="training" component={TrainingApp} >
      <Route path=":library_id/:module_id" component={TrainingModuleHandler} />
      <Route path="/training/:library_id/:module_id/:slide_id" component={TrainingSlideHandler} />
    </Route>
    <Route path="users/:username" component={UserProfile} />
    <Route path="campaigns/:campaign_slug/alerts" component={AlertsHandler} />
    <Route path="settings" component={SettingsHandler} />
    <Route path="article_finder" component={ArticleFinder} />
  </Route>
);

// The main `react_root` is only present in some Rails views, corresponding
// to the routes above.
const reactRoot = document.getElementById('react_root');
if (reactRoot) {
  // This is basic, minimal state info extracted from the HTML,
  // used for initial rendering before React fetches all the specific
  // data it needs via API calls.
  const currentUserFromHtml = JSON.parse(reactRoot.getAttribute('data-current_user'));
  const preloadedState = {
    courseCreator: {
      defaultCourseType: reactRoot.getAttribute('data-default-course-type'),
      courseStringPrefix: reactRoot.getAttribute('data-course-string-prefix'),
      useStartAndEndTimes: reactRoot.getAttribute('data-use-start-and-end-times') === 'true'
    },
    currentUserFromHtml
  };

  // This is the Redux store.
  // It is accessed from container components via `connect()`.
  // Enable Redux DevTools browser extension.
  const composeEnhancers = window.__REDUX_DEVTOOLS_EXTENSION_COMPOSE__ || compose;
  const store = createStore(
    reducer,
    preloadedState,
    composeEnhancers(applyMiddleware(thunk))
  );

  // Render the main React app
  ReactDOM.render((
    <Provider store={store} >
      <Router history={browserHistory}>
        {routes}
      </Router>
    </Provider>
  ), reactRoot);
}
