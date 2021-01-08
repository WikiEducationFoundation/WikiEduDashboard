import React from 'react';
import PropTypes from 'prop-types';
import createReactClass from 'create-react-class';
import { withRouter } from 'react-router';
import { Redirect, Route, Switch } from 'react-router-dom';

import SubNavigation from '../common/sub_navigation.jsx';
import CourseAlertsList from '../alerts/course_alerts_list';
import RevisionHandler from '../revisions/revisions_handler';

export const ActivityHandler = createReactClass({
  displayName: 'ActivityHandler',

  propTypes: {
    course_id: PropTypes.string,
    current_user: PropTypes.object,
    course: PropTypes.object,
  },

  render() {
    const links = [
      {
        href: `/courses/${this.props.course.slug}/activity/recent`,
        text: I18n.t('application.recent_activity')
      },
      {
        href: `/courses/${this.props.course.slug}/activity/alerts`,
        text: I18n.t('courses.alerts')
      }
    ];

    return (
      <div className="activity-handler">
        <SubNavigation links={links} />
        <Switch>
          <Route exact path="/courses/:course_school/:course_title/activity/recent" render={() => <RevisionHandler {...this.props}/>} />
          <Route exact path="/courses/:course_school/:course_title/activity/alerts" render={() => <CourseAlertsList {...this.props} />} />
          <Redirect to={{ pathname: '/courses/:course_school/:course_title/activity/recent' }}/>
        </Switch>
      </div>
    );
  }
});

export default withRouter(ActivityHandler);
