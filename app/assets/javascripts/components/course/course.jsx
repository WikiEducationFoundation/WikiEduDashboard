// /* eslint no-undef: 2 */
import React from 'react';
import createReactClass from 'create-react-class';
import PropTypes from 'prop-types';
import { connect } from 'react-redux';
import { parse } from 'query-string';
import { Route, Switch } from 'react-router-dom';
import { withRouter } from 'react-router';
import OverviewHandler from '../overview/overview_handler.jsx';
import TimelineHandler from '../timeline/timeline_handler.jsx';
import RevisionsHandler from '../revisions/revisions_handler.jsx';
import StudentsHandler from '../students/students_handler.jsx';
import ArticlesHandler from '../articles/articles_handler.jsx';
import UploadsHandler from '../uploads/uploads_handler.jsx';
import Resources from '../resources/resources.jsx';
import RocketChat from '../common/rocket_chat.jsx';
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

export const Course = createReactClass({
  displayName: 'Course',

  propTypes: {
    course: PropTypes.object.isRequired,
    match: PropTypes.object,
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
    const { course_school, course_title } = this.props.match.params;
    return `${course_school}/${course_title}`;
  },

  showEnrollCard(course) {
    const location = this.props.location;
    const query = parse(location.search);
    // Only show it on the main url
    if (!CourseUtils.onHomeTab(location)) { return false; }
    // Show the enroll card if either the `enroll` or `enrolled` param is present.
    // The enroll param may be blank if the course has no passcode.
    if (query.enroll !== undefined || query.enrolled) { return true; }
    // If the course has no passcode, then show the enroll card to unenrolled users
    if (this.props.currentUser.notEnrolled && course.passcode === '' && !course.ended) { return true; }
    return false;
  },

  _courseLinkParams() {
    return `/courses/${this.props.match.params.course_school}/${this.props.match.params.course_title}`;
  },

  render() {
    const courseId = this.getCourseID();
    const course = this.props.course;
    if (!courseId || !course || !course.home_wiki) { return <div />; }

    const userRoles = this.props.currentUser;
    const courseProps = { course_id: courseId, current_user: userRoles, course };
    // //////////////////
    // Enrollment modal /
    // //////////////////
    let enrollCard;
    if (this.showEnrollCard(course)) {
      const query = parse(this.props.location.search);
      enrollCard = (
        <EnrollCard
          user={this.props.currentUser}
          userRoles={userRoles}
          course={course}
          courseLink={this._courseLinkParams()}
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
              location={this.props.location}
              currentUser={this.props.currentUser}
              courseLink={this._courseLinkParams()}
            />
            <Notifications />
          </Affix>
        </div>
        <CourseAlerts
          courseAlerts={this.props.courseAlerts}
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
          <Switch>
            <Route exact path="/courses/:course_school/:course_title" render={() => <OverviewHandler {...courseProps} />} />
            <Route exact path="/courses/:course_school/:course_title/home" render={() => <OverviewHandler {...courseProps} />} />
            {/* The overview route path should not be removed in order to preserve the default url */}
            <Route exact path="/courses/:course_school/:course_title/overview" render={() => <OverviewHandler {...courseProps} />} />
            <Route exact path="/courses/:course_school/:course_title/activity" render={() => <RevisionsHandler {...courseProps} />} />
            <Route exact path="/courses/:course_school/:course_title/students" render={() => <StudentsHandler {...courseProps} />} />
            <Route path="/courses/:course_school/:course_title/articles" render={() => <ArticlesHandler {...courseProps} />} />
            <Route exact path="/courses/:course_school/:course_title/uploads" render={() => <UploadsHandler {...courseProps} />} />
            <Route exact path="/courses/:course_school/:course_title/chat" render={() => <RocketChat {...courseProps} />} />
            <Route exact path="/courses/:course_school/:course_title/article_finder" render={() => <ArticleFinder {...courseProps} />} />
            <Route path="/courses/:course_school/:course_title/timeline" render={() => <TimelineHandler {...courseProps} />} />
            <Route path="/courses/:course_school/:course_title/resources" render={() => <Resources {...courseProps} />} />
          </Switch>
        </div>
      </div>
    );
  }
});

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

export default withRouter(connect(mapStateToProps, mapDispatchToProps)(Course));
