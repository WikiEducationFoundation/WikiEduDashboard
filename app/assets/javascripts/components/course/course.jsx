// /* eslint no-undef: 2 */
import React, { useEffect } from 'react';
import { useDispatch, useSelector } from 'react-redux';
import { parse } from 'query-string';
import { Route, Routes, useLocation, useParams } from 'react-router-dom';
import OverviewHandler from '../overview/overview_handler.jsx';
import TimelineHandler from '../timeline/timeline_handler.jsx';
import StudentsTabHandler from '../students/containers/StudentsTabHandler';
import ArticlesHandler from '../articles/articles_handler.jsx';
import UploadsHandler from '../uploads/uploads_handler.jsx';
import Resources from '../resources/resources.jsx';
import ArticleFinder from '../article_finder/article_finder.jsx';

import Confirm from '../common/confirm.jsx';
import { fetchUsers } from '../../actions/user_actions.js';
import { fetchCampaigns } from '../../actions/campaign_actions.js';
import { fetchCourse, updateCourse, persistCourse, dismissNotification } from '../../actions/course_actions';
import { fetchTimeline } from '../../actions/timeline_actions';
import Affix from '../common/affix.jsx';
import CourseUtils from '../../utils/course_utils.js';
import EnrollCard from '../enroll/enroll_card.jsx';
import CourseNavbar from '../common/course_navbar.jsx';
import Notifications from '../common/notifications.jsx';
import CourseAlerts from './course_alerts';
import { getStudentCount, getCurrentUser, getWeeksArray } from '../../selectors';
import ActivityHandler from '../activity/activity_handler';
import CourseApproval from './course_approval';

export const Course = () => {
  const location = useLocation();
  const { course_school, course_title } = useParams();
  const dispatch = useDispatch();
  const { course, courseAlerts, users, weeks, usersLoaded, studentCount, currentUser } = useSelector(state => ({
    course: state.course,
    courseAlerts: state.courseAlerts,
    users: state.users.users,
    weeks: getWeeksArray(state),
    usersLoaded: state.users.isLoaded,
    studentCount: getStudentCount(state),
    currentUser: getCurrentUser(state)
  }));

  useEffect(() => {
    const courseSlug = getCourseSlug();
    dispatch(fetchCourse(courseSlug));
    dispatch(fetchUsers(courseSlug));
    dispatch(fetchTimeline(courseSlug));
    dispatch(fetchCampaigns(courseSlug));
  }, []);

  const getCourseSlug = () => {
    return `${course_school}/${course_title}`;
  };

  const showCourseApprovalForm = () => {
    // Render the form only to admins
    if (!currentUser.isAdmin) return false;
    // Render the form only on home tab
    if (!CourseUtils.onHomeTab(location)) return false;

    const isSubmitted = course.submitted;
    const isPublished = course.published;
    // Render the form only if course is submitted for approval and not yet published
    if (isSubmitted && !isPublished) return true;
    return false;
  };

  const showEnrollCard = () => {
    const query = parse(location.search);
    // Only show it on the main url
    if (!CourseUtils.onHomeTab(location)) return false;
    // Show the enroll card if either the `enroll` or `enrolled` param is present.
    // The enroll param may be blank if the course has no passcode.
    if (query.enroll !== undefined || query.enrolled) return true;
    // If the course has no passcode, then show the enroll card to unenrolled users
    if (currentUser.notEnrolled && course.passcode === '' && !course.ended) return true;
    return false;
  };

  const courseLinkParams = () => `/courses/${course_school}/${course_title}`;

  const courseSlug = getCourseSlug();
  if (!courseSlug || !course || !course.home_wiki || course.title === '') { return <div />; }

  const courseProps = { course_id: courseSlug, current_user: currentUser, course };

  let courseApprovalForm;
  if (showCourseApprovalForm()) {
    courseApprovalForm = <CourseApproval />;
  }
  // //////////////////
  // Enrollment modal /
  // //////////////////
  let enrollCard;
  if (showEnrollCard()) {
    const query = parse(location.search);
    enrollCard = (
      <EnrollCard
        user={currentUser}
        userRoles={currentUser}
        course={course}
        courseLink={courseLinkParams()}
        passcode={query.enroll}
        enrolledParam={query.enrolled}
        enrollFailureReason={query.failure_reason}
      />
    );
  }

  return (
    <div>
      <div className="course-nav__wrapper">
        <Affix className="course_navigation" offset={57}>
          <CourseNavbar
            course={course}
            location={location}
            currentUser={currentUser}
            courseLink={courseLinkParams()}
          />
          <Notifications />
        </Affix>
      </div>
      <CourseAlerts
        courseAlerts={courseAlerts}
        course={course}
        userRoles={currentUser}
        weeks={weeks}
        courseLinkParams={courseLinkParams()}
        usersLoaded={usersLoaded}
        studentCount={studentCount}
        updateCourse={updateCourse}
        persistCourse={persistCourse}
        dismissNotification={dismissNotification}
      />
      <div className="course_main container">
        <Confirm />
        {courseApprovalForm}
        {enrollCard}
        <Routes>
          <Route path="/" element={<OverviewHandler {...courseProps} />} />
          <Route path="home" element={<OverviewHandler {...courseProps} />} />
          {/* The overview route path should not be removed in order to preserve the default url */}
          <Route path="overview" element={<OverviewHandler {...courseProps} />} />
          <Route path="activity/*" element={<ActivityHandler {...courseProps} users={users} usersLoaded={usersLoaded}/>} />
          <Route path="students/*" element={<StudentsTabHandler {...courseProps} />} />
          <Route path="articles/*" element={<ArticlesHandler {...courseProps} />} />
          <Route path="uploads" element={<UploadsHandler {...courseProps} />} />
          <Route path="article_finder" element={<ArticleFinder {...courseProps} />} />
          <Route path="timeline/*" element={<TimelineHandler {...courseProps} />} />
          <Route path="resources" element={<Resources {...courseProps} />} />
        </Routes>
      </div>
    </div>
  );
};

export default Course;

