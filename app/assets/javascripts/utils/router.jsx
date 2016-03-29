import React from 'react';
import ReactDOM from 'react-dom';
import { Router, Route, IndexRoute, browserHistory } from 'react-router';

import App from '../components/app.jsx';
import Course from '../components/course.cjsx';
import Onboarding from '../components/onboarding/index.cjsx';
import Wizard from '../components/wizard/wizard.cjsx';
import Dates from '../components/timeline/meetings.cjsx';
import CourseCreator from '../components/course_creator/course_creator.cjsx';

import OverviewHandler from '../components/overview/overview_handler.cjsx';
import TimelineHandler from '../components/timeline/timeline_handler.cjsx';
import RevisionsHandler from '../components/revisions/revisions_handler.cjsx';
import StudentsHandler from '../components/students/students_handler.cjsx';
import ArticlesHandler from '../components/articles/articles_handler.cjsx';
import UploadsHandler from '../components/uploads/uploads_handler.cjsx';

import RecentActivityHandler from '../components/activity/recent_activity_handler.cjsx';
import DidYouKnowHandler from '../components/activity/did_you_know_handler.cjsx';
import PlagiarismHandler from '../components/activity/plagiarism_handler.cjsx';
import RecentEditsHandler from '../components/activity/recent_edits_handler.cjsx';

import TrainingApp from '../training/components/training_app.cjsx';
import TrainingModuleHandler from '../training/components/training_module_handler.cjsx';
import TrainingSlideHandler from '../training/components/training_slide_handler.cjsx';

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

let routes = (
  <Route path="/" component={App}>
    <Route path="onboarding" component={Onboarding.Root}>
      <IndexRoute component={Onboarding.Intro} />
      <Route path="form" component={Onboarding.Form} />
      <Route path="permissions" component={Onboarding.Permissions} />
      <Route path="finish" component={Onboarding.Finished} />
    </Route>
    <Route path="recent-activity" component={RecentActivityHandler}>
      <IndexRoute component={DidYouKnowHandler} />
      <Route path="plagiarism" component={PlagiarismHandler} />
      <Route path="recent-edits" component={RecentEditsHandler} />
    </Route>
    <Route path="courses">
      <Route path=":course_school/:course_title" component={Course}>
        <IndexRoute component={OverviewHandler} />
        <Route path="overview" component={OverviewHandler} />
        <Route path="timeline" component={TimelineHandler}>
          <Route path="wizard" component={Wizard} />
          <Route path="dates" component={Dates} />
        </Route>
        <Route path="activity" component={RevisionsHandler} />
        <Route path="students" component={StudentsHandler} />
        <Route path="articles" component={ArticlesHandler} />
        <Route path="uploads" component={UploadsHandler} />
      </Route>
    </Route>
    <Route path="course_creator" component={CourseCreator} />
    <Route path="training" component={TrainingApp} >
      <Route path=":library_id/:module_id" component={TrainingModuleHandler} />
      <Route path="/training/:library_id/:module_id/:slide_id" component={TrainingSlideHandler} />
    </Route>
  </Route>
);

const el = document.getElementById('react_root');
if (el) {
  ReactDOM.render((
    <Router history={browserHistory}>
      {routes}
    </Router>
  ), el);
}
