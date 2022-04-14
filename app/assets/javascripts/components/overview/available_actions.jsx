import React from 'react';
import createReactClass from 'create-react-class';
import PropTypes from 'prop-types';
import { connect } from 'react-redux';

import CourseUtils from '../../utils/course_utils.js';
import CourseDateUtils from '../../utils/course_date_utils.js';
import { initiateConfirm } from '../../actions/confirm_actions.js';
import { addNotification } from '../../actions/notification_actions.js';
import SalesforceLink from './salesforce_link.jsx';
import CourseStatsDownloadModal from './course_stats_download_modal.jsx';
import EmbedStatsButton from './embed_stats_button.jsx';
import CloneCourseButton from './clone_course_button.jsx';
import { enableAccountRequests } from '../../actions/new_account_actions.js';
import { needsUpdate, linkToSalesforce, updateSalesforceRecord, deleteCourse } from '../../actions/course_actions';
import { STUDENT_ROLE, ONLINE_VOLUNTEER_ROLE } from '../../constants/user_roles';
import { removeUser } from '../../actions/user_actions';

const AvailableActions = createReactClass({
  displayName: 'AvailableActions',

  propTypes: {
    course: PropTypes.object.isRequired,
    current_user: PropTypes.object.isRequired,
    initiateConfirm: PropTypes.func.isRequired,
    addNotification: PropTypes.func.isRequired,
    enableAccountRequests: PropTypes.func.isRequired,
    updateCourse: PropTypes.func.isRequired,
    linkToSalesforce: PropTypes.func.isRequired,
    deleteCourse: PropTypes.func.isRequired,
    removeUser: PropTypes.func.isRequired,
    courseCreationNotice: PropTypes.string
  },

  join(role = null) {
    const enrollURL = this.props.course.enroll_url;
    if (this.props.course.passcode === '' || role === 'online_volunteer') {
      const onConfirm = () => window.location = `${enrollURL}?role=${role}`;
      const confirmMessage = CourseUtils.i18n('join_no_passcode');
      this.props.initiateConfirm({ confirmMessage, onConfirm });
    } else {
      const onConfirm = (passcode) => {
        return window.location = `${enrollURL}${passcode}?role=${role}`;
      };
      const confirmMessage = I18n.t('courses.passcode_prompt');
      const explanation = CourseUtils.i18n('join_details', this.props.course.string_prefix);
      this.props.initiateConfirm({ confirmMessage, onConfirm, showInput: true, explanation });
    }
  },

  updateStats() {
    const updateUrl = `${window.location.origin}/courses/${this.props.course.slug}/manual_update`;
    const onConfirm = () => window.location = updateUrl;
    const confirmMessage = I18n.t('courses.confirm_manual_update');
    this.props.initiateConfirm({ confirmMessage, onConfirm });
  },

  leave() {
    const courseSlug = this.props.course.slug;
    const role = this.props.current_user.isOnlineVolunteer ? ONLINE_VOLUNTEER_ROLE : STUDENT_ROLE;
    const userRecord = { user: { user_id: this.props.current_user.id, role: role } };
    const leaveCourse = this.props.removeUser;
    const onConfirm = () => leaveCourse(courseSlug, userRecord);
    const confirmMessage = I18n.t('courses.leave_confirmation');
    this.props.initiateConfirm({ confirmMessage, onConfirm });
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

  enableRequests() {
    const enableRequests = this.props.enableAccountRequests;
    const notify = this.props.addNotification;
    const course = this.props.course;
    const updateCourse = this.props.updateCourse;
    const onConfirm = () => {
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
    this.props.initiateConfirm({ confirmMessage, onConfirm, showInput: false, explanation });
  },

  render() {
    const course = this.props.course;
    const controls = [];
    const user = this.props.current_user;
    const urlParams = new URLSearchParams(window.location.search);
    const isEnrollmentURL = urlParams.has('enroll');
    // If user has a role in the course or is an admin
    if ((user.isEnrolled) || user.admin || user.isAdvancedRole) {
      // If user is a student, show the 'leave' button.
      if (user.isStudent || user.isOnlineVolunteer) {
        // 'Leave' is not available if the course is controlled by Event Center.
        if (!course.flags.event_sync) {
          controls.push((
            <div key="leave" className="available-action"><button onClick={this.leave} className="button">{CourseUtils.i18n('leave_course', course.string_prefix)}</button></div>
          ));
        }
      }
      // If course is not published, show the 'delete' button to instructors and admins.
      // Show a disabled version of it on P&E Dashboard even if a course is published,
      // so that users can see the instructions for how to enable deletion.
      if ((user.isAdvancedRole || user.admin) && (!course.published || !Features.wikiEd)) {
        controls.push((
          <div title={I18n.t('courses.delete_course_instructions')} key="delete" className="available-action">
            <button className="button danger" onClick={this.delete}>
              {CourseUtils.i18n('delete_course', course.string_prefix)}
            </button>
          </div>
        ));
      }
      // If the course is ended, show the 'needs update' button.
      if (CourseDateUtils.isEnded(course)) {
        controls.push((
          <div key="needs_update" className="available-action"><button className="button" onClick={this.needsUpdate}>{I18n.t('courses.needs_update')}</button></div>
        ));
      }
    // If user has no role or is logged out, and if he is not on enrollment page, show 'Join course' button.
    // On enrollment page, 'Join course' button is not shown in Actions component to avoid confusion.
    // The 'Join course' button is not shown for courses controlled by Wikimedia Event Center
    } else if (!course.ended && !isEnrollmentURL && !course.flags.event_sync) {
      controls.push(
        <div key="join" className="available-action"><button onClick={this.join} className="button">{CourseUtils.i18n('join_course', course.string_prefix)}</button></div>
      );
      // On P&E Dashboard, offer option to join as online volunteer
      if (!Features.wikiEd && course.online_volunteers_enabled) {
        controls.push(
          <div key="volunteer" className="available-action"><button onClick={() => this.join('online_volunteer')} className="button">{CourseUtils.i18n('join_course_as_volunteer', course.string_prefix)}</button></div>
        );
      }
    }
    // If the user is enrolled in the course or admin, and the course type is editathon and not finished, show a manual stats update button
    // NOTE: This is disabled until we have a better way to prevent manual updates from overloading the system.
    // if ((user.isEnrolled || user.isAdmin) && (course.type === 'Editathon' && !course.ended)) {
    //   controls.push((
    //     <div key="updateStats" className="available-action"><button className="button" onClick={this.updateStats}>{I18n.t('courses.update_stats')}</button></div>
    //   ));
    // }

    // Requested accounts
    // These are enabled for instructors on P&E Dashboard, but only for admins on Wiki Education Dashboard.
    if ((user.isAdvancedRole && !Features.wikiEd) || user.admin) {
      // Enable account requests if allowed
      if (!course.account_requests_enabled) {
        controls.push((
          <div key="enable_account_requests" className="available-action"><button onClick={this.enableRequests} className="button">{I18n.t('courses.enable_account_requests')}</button></div>
        ));
      }
    }

    // If the user is an instructor or admin, and the course is published, show a stats download button
    // Always show the stats download for published non-Wiki Ed courses.
    if ((user.isAdvancedRole || user.admin || !Features.wikiEd) && course.published) {
      controls.push((
        <div key="download_course_stats" className="available-action"><CourseStatsDownloadModal course={course} /></div>
      ));
      controls.push((
        <div key="embed_course_stats" className="available-action"><EmbedStatsButton title={course.title} /></div>
      ));
    }

    // If the user is an admin and the course is both published and a Wiki-Ed course.
    if (user.admin && course.published) {
      controls.push((
        <div key="clone_course" className="available-action"><CloneCourseButton courseId={course.id} courseCreationNotice={this.props.courseCreationNotice}/></div>
      ));
    }

    // If no controls are available
    if (controls.length === 0) {
      controls.push(
        <div key="none" className="available-action">{I18n.t('courses.no_available_actions')}</div>
      );
    }

    return (
      <div className="module actions">
        <div className="section-header">
          <h3>{I18n.t('courses.actions')}</h3>
        </div>
        <div className="module__data">
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
  needsUpdate,
  linkToSalesforce,
  updateSalesforceRecord,
  deleteCourse,
  removeUser
};

export default connect(null, mapDispatchToProps)(AvailableActions);
