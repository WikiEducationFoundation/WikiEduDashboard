import React, { useEffect } from 'react';
import PropTypes from 'prop-types';
import { connect } from 'react-redux';
import { parse } from 'query-string';
import { Route, Routes } from 'react-router-dom';
import withRouter from '../util/withRouter';
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
import CourseUtils from '../../utils/course_utils.js';
import EnrollCard from '../enroll/enroll_card.jsx';
import CourseNavbar from '../common/course_navbar.jsx';
import Notifications from '../common/notifications.jsx';
import CourseAlerts from './course_alerts';
import { getStudentCount, getCurrentUser, getWeeksArray } from '../../selectors';
import ActivityHandler from '../activity/activity_handler';
import CourseApproval from './course_approval';

const Course = withRouter((props) => {
  useEffect(() => {
    // Fetch all the data needed to render a course page
    const courseSlug = getCourseSlug();
    props.fetchCourse(courseSlug);
    props.fetchUsers(courseSlug);
    props.fetchTimeline(courseSlug);
    props.fetchCampaigns(courseSlug);
  }, []);

  const getCourseSlug = () => {
    const { course_school, course_title } = props.router.params;
    return `${course_school}/${course_title}`;
  };
  const showCourseApprovalForm = () => {
    // Render the form only to admins
    if (!props.currentUser.isAdmin) { return false; }
    // Render the form only on home tab
    if (!CourseUtils.onHomeTab(props.router.location)) { return false; }

    const isSubmitted = props.course.submitted;
    const isPublished = props.course.published;
    // Render the form only if course is submitted for approval and not yet published
    if (isSubmitted && !isPublished) { return true; }
    return false;
  };

  const showEnrollCard = (course) => {
    const location = props.router.location;
    const query = parse(location.search);
    // Only show it on the main url
    if (!CourseUtils.onHomeTab(location)) { return false; }
    // Show the enroll card if either the `enroll` or `enrolled` param is present.
    // The enroll param may be blank if the course has no passcode.
    if (query.enroll !== undefined || query.enrolled) { return true; }
    // If the course has no passcode, then show the enroll card to unenrolled users
    if (props.currentUser.notEnrolled && course.passcode === '' && !course.ended) { return true; }
    return false;
  };

  const _courseLinkParams = () => `/courses/${props.router.params.course_school}/${props.router.params.course_title}`;

  const courseSlug = getCourseSlug();
  const course = props.course;
  if (!courseSlug || !course || !course.home_wiki || course.title === '') {
    return <div />;
  }

  const userRoles = props.currentUser;
  const courseProps = {
    course_id: courseSlug,
    current_user: userRoles,
    course,
  };

  let courseApprovalForm;
  if (showCourseApprovalForm()) {
    courseApprovalForm = <CourseApproval />;
  }
  // //////////////////
  // Enrollment modal /
  // //////////////////
  let enrollCard;
  if (showEnrollCard(course)) {
    const query = parse(props.router.location.search);
    enrollCard = (
      <EnrollCard
        user={props.currentUser}
        userRoles={userRoles}
        course={course}
        courseLink={_courseLinkParams()}
        passcode={query.enroll}
        enrolledParam={query.enrolled}
        enrollFailureReason={query.failure_reason}
      />
    );
  }

  return (
    <div>
      <div className="course-nav__wrapper">
        <div className="course_navigation">
          <CourseNavbar
            course={course}
            location={props.router.location}
            currentUser={props.currentUser}
            courseLink={_courseLinkParams()}
          />
          <Notifications />
        </div>
      </div>
      <CourseAlerts
        courseAlerts={props.courseAlerts}
        course={course}
        userRoles={userRoles}
        weeks={props.weeks}
        courseLinkParams={_courseLinkParams()}
        usersLoaded={props.usersLoaded}
        studentCount={props.studentCount}
        updateCourse={props.updateCourse}
        persistCourse={props.persistCourse}
        dismissNotification={props.dismissNotification}
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
          <Route path="activity/*" element={<ActivityHandler {...courseProps} users={props.users} usersLoaded={props.usersLoaded} />}/>
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
});

Course.propTypes = {
  course: PropTypes.object.isRequired,
  match: PropTypes.object,
  location: PropTypes.object,
  children: PropTypes.node,
  currentUser: PropTypes.object,
  updateCourse: PropTypes.func.isRequired,
  persistCourse: PropTypes.func.isRequired,
  fetchTimeline: PropTypes.func.isRequired,
};

const mapStateToProps = state => ({
  courseAlerts: state.courseAlerts,
  course: state.course,
  users: state.users.users,
  weeks: getWeeksArray(state),
  usersLoaded: state.users.isLoaded,
  studentCount: getStudentCount(state),
  currentUser: getCurrentUser(state)
});

const mapDispatchToProps = {
  fetchUsers,
  fetchCampaigns,
  fetchCourse,
  fetchTimeline,
  updateCourse,
  persistCourse,
  dismissNotification
};

export default connect(mapStateToProps, mapDispatchToProps)(withRouter(Course));
