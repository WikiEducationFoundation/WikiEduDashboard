import React from 'react';
import createReactClass from 'create-react-class';
import PropTypes from 'prop-types';
import { connect } from 'react-redux';
import moment from 'moment';

import CourseLink from './common/course_link.jsx';
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
import OptInNotification from './common/opt_in_notification';
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

  storeDidChange() {
    return this.setState(getState());
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

  submit(e) {
    e.preventDefault();
    if (!confirm(I18n.t('courses.warn_mirrored'))) { return; }
    this.props.updateCourse({ submitted: true });
    return this.props.persistCourse(this.props.course.slug);
  },

  dismissSurvey(surveyNotificationId) {
    if (confirm(I18n.t('courses.dismiss_survey_confirm'))) {
      return this.props.dismissNotification(surveyNotificationId);
    }
  },

  _courseLinkParams() {
    return `/courses/${this.props.params.course_school}/${this.props.params.course_title}`;
  },

  render() {
    const courseId = this.getCourseID();
    const course = this.props.course;
    if (!courseId || !course || !course.home_wiki) { return <div />; }

    const alerts = [];
    const userRoles = this.props.currentUser;
    // //////////////////////////////////
    // Admin / Instructor notifications /
    // //////////////////////////////////

    // For unpublished courses, when viewed by an instructor or admin
    if (userRoles.isNonstudent && !course.legacy && !course.published) {
      // If it's an unsubmitted ClassroomProgramCourse
      const isUnsubmittedClassroomProgramCourse = !course.submitted && course.type === 'ClassroomProgramCourse';
      if (isUnsubmittedClassroomProgramCourse) {
        // Show submit button if there is a timeline with trainings, or user is admin.
        if (CourseUtils.hasTrainings(this.props.weeks) || userRoles.isAdmin) {
          alerts.push((
            <div className="notification" key="submit">
              <div className="container">
                <p>{I18n.t('courses.review_timeline')}</p>
                <a href="#" onClick={this.submit} className="button">{I18n.t('application.submit')}</a>
              </div>
            </div>
          ));
        // Show 'add trainings' message if there is a timeline with no trainings
        } else if (this.props.weeks.length) {
          alerts.push((
            <div className="notification" key="submit">
              <div className="container">
                <p>Please add student trainings to your assignment timeline. Assigning training modules is an essential part of Wiki Ed&apos;s best practices.</p>
                <a href={`${this._courseLinkParams()}/timeline`} className="button">Go to Timeline</a>
              </div>
            </div>
          ));
        // Show 'create a timeline' message if there is no timeline.
        } else {
          alerts.push((
            <div className="notification" key="submit">
              <div className="container">
                <p>Please create a timeline for your course. You can build one from scratch from the Timeline tab, or use the Assignment Wizard to create a custom timeline based on Wiki Ed&apos;s best practices.</p>
                <a href={`${this._courseLinkParams()}/timeline/wizard`} className="button">Launch the Wizard</a>
              </div>
            </div>
          ));
        }
      }

      // When the course has been submitted
      if (course.submitted) {
        // Show instructors the 'submitted' notice.
        if (!userRoles.isAdmin) {
          alerts.push((
            <div className="notification" key="submit">
              <div className="container">
                <p>{I18n.t('courses.submitted_note')}</p>
              </div>
            </div>
          ));
        // Instruct admins to approve the course by adding a campaign.
        } else {
          const homeLink = `${this._courseLinkParams()}/home`;
          alerts.push((
            <div className="notification" key="publish">
              <div className="container">
                <p>{I18n.t('courses.submitted_admin')}</p>
                <CourseLink to={homeLink} className="button">{I18n.t('courses.overview')}</CourseLink>
              </div>
            </div>
          ));
        }
      }
    }

    // For published courses with no students, highlight the enroll link
    const hasNoStudents = this.props.usersLoaded && this.props.studentCount === 0;
    if (userRoles.isNonstudent && course.published && hasNoStudents && !course.legacy) {
      const enrollEquals = '?enroll=';
      const url = window.location.origin + this._courseLinkParams() + enrollEquals + course.passcode;
      alerts.push((
        <div className="notification" key="enroll">
          <div className="container">
            <div>
              <p>{CourseUtils.i18n('published', course.string_prefix)}</p>
              <a href={url}>{url}</a>
            </div>
          </div>
        </div>
      )
      );
    }

    // ////////////////////////
    // Training notifications /
    // ////////////////////////
    if (course.incomplete_assigned_modules && course.incomplete_assigned_modules.length) {
      // `table` key is because it comes back as an openstruct
      const module = course.incomplete_assigned_modules[0].table;
      const messageKey = moment().isAfter(module.due_date, 'day') ? 'courses.training_overdue' : 'courses.training_due';

      alerts.push(
        <div className="notification" key="upcoming_module">
          <div className="container">
            <p>{I18n.t(messageKey, { title: module.title, date: module.due_date })}</p>
            <a href={module.link} className="button pull-right">{I18n.t('courses.training_nav')}</a>
          </div>
        </div>
      );
    }

    // //////////////////////
    // Survey notifications /
    // //////////////////////
    if (course.survey_notifications && course.survey_notifications.length) {
      course.survey_notifications.map((notification) => {
        const dismissOnClick = () => this.dismissSurvey(notification.id);
        return alerts.push(
          <div className="notification notification--survey" key={'survey_notification_#{notification.id}'}>
            <div className="container">
              <p>{notification.message || CourseUtils.i18n('survey.notification_message', course.string_prefix)}</p>
              <a href={notification.survey_url} className="button pull-right">{CourseUtils.i18n('survey.link', course.string_prefix)}</a>
              <button className="button small pull-right border inverse-border" onClick={dismissOnClick}>{I18n.t('courses.dismiss_survey')}</button>
            </div>
          </div>
        );
      }
      );
    }

    // //////////////////////////
    // Experiment notifications /
    // //////////////////////////
    if (course.experiment_notification) {
      alerts.push(<OptInNotification notification={course.experiment_notification} key="opt_in" />);
    }

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
        <div className="course-alerts">
          {alerts}
        </div>
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
