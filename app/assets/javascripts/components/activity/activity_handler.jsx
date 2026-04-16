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

  const showEndedNotification = props.usersLoaded && CourseDateUtils.isEndedTenDaysAgo(course);

  const endedNotification = showEndedNotification ? (
    <div
      className="notification"
      style={{
        position: 'sticky',
        top: '55px',
        zIndex: 98,
        textAlign: 'left',
        backgroundColor: '#40AD90',
        color: 'white',
        padding: '15px 0',
        marginLeft: 'calc(-50vw + 50%)',
        marginRight: 'calc(-50vw + 50%)',
        marginTop: '-30px',
        marginBottom: '30px',
        width: '100vw'
      }}
    >
      <div className="container" style={{ margin: '0 auto', maxWidth: '1200px', padding: '0 15px' }}>
        <p style={{ margin: 0, fontWeight: 'bold' }}>{I18n.t('revisions.course_ended_notification')}</p>
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
