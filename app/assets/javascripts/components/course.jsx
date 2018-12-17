// /* eslint no-undef: 2 */
import React from 'react';
import createReactClass from 'create-react-class';
import PropTypes from 'prop-types';
import { connect } from 'react-redux';

import Confirm from './common/confirm.jsx';
import { fetchUsers } from '../actions/user_actions.js';
import { fetchCampaigns } from '../actions/campaign_actions.js';
import { fetchCourse, updateCourse, persistCourse, dismissNotification } from '../actions/course_actions';
import { fetchTimeline } from '../actions/timeline_actions';
import Affix from './common/affix.jsx';
import CourseUtils from '../utils/course_utils.js';
import EnrollCard from './enroll/enroll_card.jsx';
import CourseNavbar from './common/course_navbar.jsx';
import Notifications from './common/notifications.jsx';
import CourseAlerts from './course_alerts';
import { getStudentCount, getCurrentUser, getWeeksArray } from '../selectors';

const Course = createReactClass({
  displayName: 'Course',

  propTypes: {
    course: PropTypes.object.isRequired,
    params: PropTypes.object,
    location: PropTypes.object,
    children: PropTypes.node,
    currentUser: PropTypes.object,
    updateCourse: PropTypes.func.isRequired,
    persistCourse: PropTypes.func.isRequired,
    fetchTimeline: PropTypes.func.isRequired
  },

  // Fetch all the data needed to render a course page
  componentDidMount() {
    const courseID = this.getCourseID();
    this.props.fetchCourse(courseID);
    this.props.fetchUsers(courseID);
    this.props.fetchTimeline(courseID);
    return this.props.fetchCampaigns(courseID);
  },

  getCourseID() {
    const { params } = this.props;
    return `${params.course_school}/${params.course_title}`;
  },

  showEnrollCard(course) {
    const location = this.props.location;
    // Only show it on the main url
    if (!CourseUtils.onCourseIndex(location)) { return false; }
    // Show the enroll card if either the `enroll` or `enrolled` param is present.
    // The enroll param may be blank if the course has no passcode.
    if (location.query.enroll !== undefined || location.query.enrolled) { return true; }
    // If the course has no passcode, then show the enroll card to unenrolled users
    if (this.props.currentUser.notEnrolled && course.passcode === '' && !course.ended) { return true; }
    return false;
  },

  _courseLinkParams() {
    return `/courses/${this.props.params.course_school}/${this.props.params.course_title}`;
  },

  render() {
    const courseId = this.getCourseID();
    const course = this.props.course;
    if (!courseId || !course || !course.home_wiki) { return <div />; }

    const userRoles = this.props.currentUser;

    // //////////////////
    // Enrollment modal /
    // //////////////////
    let enrollCard;
    if (this.showEnrollCard(course)) {
      enrollCard = (
        <EnrollCard
          user={this.props.currentUser}
          userRoles={userRoles}
          course={course}
          courseLink={this._courseLinkParams()}
          passcode={this.props.location.query.enroll}
          enrolledParam={this.props.location.query.enrolled}
          enrollFailureReason={this.props.location.query.failure_reason}
        />
      );
    }

    return (
      <div>
        <div className="course-nav__wrapper">
          <Affix className="course_navigation" offset={57}>
            <CourseNavbar
              course={course}
              location={this.props.location}
              currentUser={this.props.currentUser}
              courseLink={this._courseLinkParams()}
            />
            <Notifications />
          </Affix>
        </div>
        <CourseAlerts
          course={course}
          userRoles={userRoles}
          weeks={this.props.weeks}
          courseLinkParams={this._courseLinkParams()}
          usersLoaded={this.props.usersLoaded}
          studentCount={this.props.studentCount}
          updateCourse={this.props.updateCourse}
          persistCourse={this.props.persistCourse}
          dismissNotification={this.props.dismissNotification}
        />
        <div className="course_main container">
          <Confirm />
          {enrollCard}
          {React.cloneElement(this.props.children, { course_id: courseId, current_user: this.props.currentUser, course })}
        </div>
      </div>
    );
  }
});

const mapStateToProps = state => ({
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

export default connect(mapStateToProps, mapDispatchToProps)(Course);
