import React from 'react';
import PropTypes from 'prop-types';
import { Navigate, Route, Routes } from 'react-router-dom';

import SubNavigation from '../common/sub_navigation.jsx';
import CourseAlertsList from '../alerts/course_alerts_list';
import RevisionHandler from '../revisions/revisions_handler';
import CourseDateUtils from '../../utils/course_date_utils';

const ActivityHandler = (props) => {
  const { course, current_user } = props;
  const links = [
    {
      href: `/courses/${course.slug}/activity/recent`,
      text: I18n.t('application.recent_activity')
    }
  ];

  if (current_user.admin || !Features.wikiEd) {
    links.push({
      href: `/courses/${course.slug}/activity/alerts`,
      text: I18n.t('courses.alerts')
    });
  }

  const showEndedNotification = props.usersLoaded && CourseDateUtils.isEnded(course);

  const endedNotification = showEndedNotification ? (
    <div className="notification notification--course-ended">
      <div className="container">
        <p>{I18n.t('revisions.course_ended_notification')}</p>
      </div>
    </div>
  ) : null;

  return (
    <div className="activity-handler">
      {endedNotification}
      <SubNavigation links={links} />
      <Routes>
        {props.usersLoaded && <Route path="recent" element={<RevisionHandler {...props} />} />}
        <Route path="alerts" element={<CourseAlertsList {...props} />} />
        <Route path="*" element={<Navigate replace to="recent" />} />
      </Routes>
    </div>
  );
};

ActivityHandler.propTypes = {
  course_id: PropTypes.string,
  current_user: PropTypes.object,
  course: PropTypes.object,
};

export default ActivityHandler;
