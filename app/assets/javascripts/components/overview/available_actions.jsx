import React from 'react';
import createReactClass from 'create-react-class';
import PropTypes from 'prop-types';
import { connect } from 'react-redux';

import { enableForCourse } from '../../actions/chat_actions.js';
import CourseUtils from '../../utils/course_utils.js';
import CourseDateUtils from '../../utils/course_date_utils.js';
import { initiateConfirm } from '../../actions/confirm_actions.js';
import { addNotification } from '../../actions/notification_actions.js';
import SalesforceLink from './salesforce_link.jsx';
import GreetStudentsButton from './greet_students_button.jsx';
import CourseStatsDownloadModal from './course_stats_download_modal.jsx';
import EmbedStatsButton from './embed_stats_button.jsx';
import CloneCourseButton from './clone_course_button.jsx';
import { enableAccountRequests } from '../../actions/new_account_actions.js';
import { needsUpdate, linkToSalesforce, updateSalesforceRecord, deleteCourse, greetStudents } from '../../actions/course_actions';
import { removeUser } from '../../actions/user_actions';

const AvailableActions = createReactClass({
  displayName: 'AvailableActions',

  propTypes: {
    course: PropTypes.object.isRequired,
    current_user: PropTypes.object.isRequired,
    initiateConfirm: PropTypes.func.isRequired,
    addNotification: PropTypes.func.isRequired,
    enableAccountRequests: PropTypes.func.isRequired,
    enableForCourse: PropTypes.func.isRequired,
    updateCourse: PropTypes.func.isRequired,
    linkToSalesforce: PropTypes.func.isRequired,
    deleteCourse: PropTypes.func.isRequired,
    greetStudents: PropTypes.func.isRequired,
    removeUser: PropTypes.func.isRequired
  },

  join() {
    if (this.props.course.passcode === '') {
      const EnrollURL = this.props.course.enroll_url;
      const onConfirm = function () {
        return window.location = EnrollURL;
      };
      const confirmMessage = CourseUtils.i18n('join_no_passcode');
      this.props.initiateConfirm(confirmMessage, onConfirm);
    } else {
      const EnrollURL = this.props.course.enroll_url;
      const onConfirm = function (passcode) {
      return window.location = EnrollURL + passcode;
      };
      const confirmMessage = I18n.t('courses.passcode_prompt');
      const joinDescription = CourseUtils.i18n('join_details', this.props.course.string_prefix);
      this.props.initiateConfirm(confirmMessage, onConfirm, true, joinDescription);
    }
  },

  updateStats() {
    const updateUrl = `${window.location.origin}/courses/${this.props.course.slug}/manual_update`;
    const onConfirm = function () {
      return window.location = updateUrl;
    };
    const confirmMessage = I18n.t('courses.confirm_manual_update');
    this.props.initiateConfirm(confirmMessage, onConfirm);
  },

  leave() {
    const courseSlug = this.props.course.slug;
    const userRecord = { user: { user_id: this.props.current_user.id, role: 0 } };
    const leaveCourse = this.props.removeUser;
    const onConfirm = function () {
      return leaveCourse(courseSlug, userRecord);
    };
    const confirmMessage = I18n.t('courses.leave_confirmation');
    this.props.initiateConfirm(confirmMessage, onConfirm);
  },

  delete() {
    // The action is only available once a course has been removed from all campaigns.
    if (this.props.course.published) {
      return alert(I18n.t('courses.delete_course_instructions'));
    }

    const enteredTitle = prompt(I18n.t('courses.confirm_course_deletion', { title: this.props.course.title }));
    if (enteredTitle.trim() === this.props.course.title.trim()) {
      return this.props.deleteCourse(this.props.course.slug);
    } else if (enteredTitle) {
      return alert(I18n.t('courses.confirm_course_deletion_failed', { title: enteredTitle }));
    }
  },

  needsUpdate() {
    this.props.needsUpdate(this.props.course.slug);
  },

  enableChat() {
    const course = this.props.course.id;
    const onConfirm = function () {
      return this.props.enableForCourse({ course });
    };
    const confirmMessage = 'Are you sure you want to enable chat?';
    this.props.initiateConfirm(confirmMessage, onConfirm);
  },

  enableRequests() {
    const enableRequests = this.props.enableAccountRequests;
    const notify = this.props.addNotification;
    const course = this.props.course;
    const updateCourse = this.props.updateCourse;
    const onConfirm = function () {
      enableRequests(course);
      updateCourse(course);
      notify({
        message: I18n.t('courses.accounts_generation_enabled'),
        closable: true,
        type: 'success'
      });
    };
    const confirmMessage = I18n.t('courses.accounts_generation_confirm_message');
    const explanation = I18n.t('courses.accounts_generation_explanation');
    this.props.initiateConfirm(confirmMessage, onConfirm, false, explanation);
  },

  render() {
    const course = this.props.course;
    const controls = [];
    const user = this.props.current_user;
    // If user has a role in the course or is an admin
    if ((user.isEnrolled) || user.admin) {
      // If user is a student, show the 'leave' button.
      if (user.isStudent) {
        controls.push((
          <p key="leave"><button onClick={this.leave} className="button">{CourseUtils.i18n('leave_course', course.string_prefix)}</button></p>
        ));
      }
      // If course is not published, show the 'delete' button to instructors and admins.
      // Show a disabled version of it on P&E Dashboard even if a course is published,
      // so that users can see the instructions for how to enable deletion.
      if ((user.isNonstudent || user.admin) && (!course.published || !Features.wikiEd)) {
        controls.push((
          <p title={I18n.t('courses.delete_course_instructions')} key="delete">
            <button className="button danger" onClick={this.delete}>
              {CourseUtils.i18n('delete_course', course.string_prefix)}
            </button>
          </p>
        ));
      }
      // If the course is ended, show the 'needs update' button.
      if (CourseDateUtils.isEnded(course)) {
        controls.push((
          <p key="needs_update"><button className="button" onClick={this.needsUpdate}>{I18n.t('courses.needs_update')}</button></p>
        ));
      }
      // If chat is available but not enabled for course, show the 'enable chat' button.
      if (Features.enableChat && !course.flags.enable_chat && user.admin) {
        controls.push((
          <p key="enable_chat"><button className="button" onClick={this.enableChat}>{I18n.t('courses.enable_chat')}</button></p>
        ));
      }
    // If user has no role or is logged out
    } else if (!course.ended) {
      controls.push((
        <p key="join"><button onClick={this.join} className="button">{CourseUtils.i18n('join_course', course.string_prefix)}</button></p>
      ));
    }
    // If the user is enrolled in the course or admin, and the course type is editathon and not finished, show a manual stats update button
    if ((user.isEnrolled || user.isAdmin) && (course.type === 'Editathon' && !course.ended)) {
      controls.push((
        <p key="updateStats"><button className="button" onClick={this.updateStats}>{I18n.t('courses.update_stats')}</button></p>
      ));
    }

    // Requested accounts
    // These are enabled for instructors on P&E Dashboard, but only for admins on Wiki Education Dashboard.
    if ((user.isNonstudent && !Features.wikiEd) || user.admin) {
      // Enable account requests if allowed
      if (!course.account_requests_enabled) {
        controls.push((
          <p key="enable_account_requests"><button onClick={this.enableRequests} className="button">{I18n.t('courses.enable_account_requests')}</button></p>
        ));
      }
    }

    // If the user is an instructor or admin, and the course is published, show a stats download button
    // Always show the stats download for published non-Wiki Ed courses.
    if ((user.isNonstudent || user.admin || !Features.wikiEd) && course.published) {
      controls.push((
        <p key="download_course_stats"><CourseStatsDownloadModal course={course} /></p>
      ));
      controls.push((
        <p key="embed_course_stats"><EmbedStatsButton title={course.title} /></p>
      ));
    }

    // If the user is an admin and the course is both published and a Wiki-Ed course.
    if (user.admin && Features.wikiEd && course.published) {
      controls.push((
        <p key="clone_course"><CloneCourseButton courseId={course.id}/></p>
      ));
    }

    // If no controls are available
    if (controls.length === 0) {
      controls.push(
        <p key="none">{I18n.t('courses.no_available_actions')}</p>
      );
    }

    return (
      <div className="module actions">
        <div className="section-header">
          <h3>{I18n.t('courses.actions')}</h3>
        </div>
        <div className="module__data">
          <GreetStudentsButton course={course} current_user={this.props.current_user} greetStudents={this.props.greetStudents} />
          {controls}
          <SalesforceLink course={course} current_user={this.props.current_user} linkToSalesforce={this.props.linkToSalesforce} updateSalesforceRecord={this.props.updateSalesforceRecord} />
        </div>
      </div>
    );
  }
}
);

const mapDispatchToProps = {
  initiateConfirm,
  addNotification,
  enableAccountRequests,
  enableForCourse,
  needsUpdate,
  linkToSalesforce,
  updateSalesforceRecord,
  deleteCourse,
  greetStudents,
  removeUser
};

export default connect(null, mapDispatchToProps)(AvailableActions);
