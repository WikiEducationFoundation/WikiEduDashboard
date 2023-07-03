import React from 'react';
import PropTypes from 'prop-types';
import { Navigate, Route, Routes } from 'react-router-dom';

import SubNavigation from '../common/sub_navigation.jsx';
import CourseAlertsList from '../alerts/course_alerts_list';
import RevisionHandler from '../revisions/revisions_handler';
import PossiblePlagiarismHandler from '../suspected_plagiarism/suspected_plagiarism_handler';

const ActivityHandler = (props) => {
  const { course, current_user } = props;
  const links = [
    {
      href: `/courses/${course.slug}/activity/recent`,
      text: I18n.t('application.recent_activity')
    },
    {
      href: `/courses/${course.slug}/activity/plagiarism`,
      text: I18n.t('recent_activity.possible_plagiarism')
    },
  ];

  if (current_user.admin) {
    links.push({
      href: `/courses/${course.slug}/activity/alerts`,
      text: I18n.t('courses.alerts')
    });
  }

  return (
    <div className="activity-handler">
      <SubNavigation links={links} />
      <Routes>
        {props.usersLoaded && <Route path="recent" element={<RevisionHandler {...props} />} />}
        <Route path="alerts" element={<CourseAlertsList {...props} />} />
        <Route path="plagiarism" element={<PossiblePlagiarismHandler {...props} />} />
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
