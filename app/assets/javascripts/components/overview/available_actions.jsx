import React from 'react';
import createReactClass from 'create-react-class';
import PropTypes from 'prop-types';
import { connect } from "react-redux";

import ServerActions from '../../actions/server_actions.js';
import { enableForCourse } from '../../actions/chat_actions.js';
import CourseStore from '../../stores/course_store.js';
import CourseUtils from '../../utils/course_utils.js';
import CourseDateUtils from '../../utils/course_date_utils.js';
import { initiateConfirm } from '../../actions/confirm_actions.js';
import { addNotification } from '../../actions/notification_actions.js';
import SalesforceLink from './salesforce_link.jsx';
import GreetStudentsButton from './greet_students_button.jsx';
import CourseStatsDownloadModal from './course_stats_download_modal.jsx';
import { enableAccountRequests } from '../../actions/new_account_actions.js';
import CourseActions from '../../actions/course_actions.js';

const getState = () => ({ course: CourseStore.getCourse() });

const AvailableActions = createReactClass({
  displayName: 'Actions',

  propTypes: {
    current_user: PropTypes.object
  },

  mixins: [CourseStore.mixin],

  getInitialState() {
    return ({
      course: CourseStore.getCourse()
    });
  },

  storeDidChange() {
    return this.setState(getState());
  },

  join() {
    if (this.state.course.passcode === '') {
      const EnrollURL = this.state.course.enroll_url;
      const onConfirm = function () {
        return window.location = EnrollURL;
      };
      const confirmMessage = CourseUtils.i18n('join_no_passcode');
      this.props.initiateConfirm(confirmMessage, onConfirm);
    } else {
      const EnrollURL = this.state.course.enroll_url;
      const onConfirm = function (passcode) {
      return window.location = EnrollURL + passcode;
      };
      const confirmMessage = I18n.t('courses.passcode_prompt');
      const joinDescription = CourseUtils.i18n('join_details', this.state.course.string_prefix);
      this.props.initiateConfirm(confirmMessage, onConfirm, true, joinDescription);
    }
  },

  updateStats() {
    const updateUrl = `${window.location.origin}/courses/${this.state.course.slug}/manual_update`;
    const onConfirm = function () {
      return window.location = updateUrl;
    };
    const confirmMessage = I18n.t('courses.confirm_manual_update');
    this.props.initiateConfirm(confirmMessage, onConfirm);
  },

  leave() {
    const course = this.state.course.slug;
    const currentUserId = this.props.current_user.id;
    const onConfirm = function () {
      return ServerActions.remove('user', course, { user: { user_id: currentUserId, role: 0 } });
    };
    const confirmMessage = I18n.t('courses.leave_confirmation');
    this.props.initiateConfirm(confirmMessage, onConfirm);
  },

  delete() {
    const enteredTitle = prompt(I18n.t('courses.confirm_course_deletion', { title: this.state.course.title }));
    if (enteredTitle === this.state.course.title) {
      return ServerActions.deleteCourse(this.state.course.slug);
    } else if (enteredTitle) {
      return alert(I18n.t('courses.confirm_course_deletion_failed', { title: enteredTitle }));
    }
  },

  needsUpdate() {
    ServerActions.needsUpdate(this.state.course.slug);
  },

  enableChat() {
    const course = this.state.course.id;
    const onConfirm = function () {
      return this.props.enableForCourse({ course });
    };
    const confirmMessage = 'Are you sure you want to enable chat?';
    this.props.initiateConfirm(confirmMessage, onConfirm);
  },

  enableRequests() {
    const enableRequests = this.props.enableAccountRequests;
    const notify = this.props.addNotification;
    const course = this.state.course;
    const onConfirm = function () {
      enableRequests(course);
      CourseActions.updateCourse(course);
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
    const course = this.state.course;
    const controls = [];
    const user = this.props.current_user;
    // If user has a role in the course or is an admin
    if ((user.role !== undefined) || user.admin) {
      // If user is a student, show the 'leave' button.
      if (user.role === 0) {
        controls.push((
          <p key="leave"><button onClick={this.leave} className="button">{CourseUtils.i18n('leave_course', course.string_prefix)}</button></p>
        ));
      }
      // If course is not published, show the 'delete' button to instructors and admins.
      // Show a disabled version of it on P&E Dashboard even if a course is published,
      // so that users can see the instructions for how to enable deletion.
      if ((user.role === 1 || user.admin) && (!course.published || !Features.wikiEd)) {
        // The action is only available once a course has been removed from all campaigns.
        const disabled = course.published;
        controls.push((
          <p title={I18n.t('courses.delete_course_instructions')} key="delete">
            <button disabled={disabled} className="button danger" onClick={this.delete}>
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
    if (Features.enableAccountRequests && (user.role === 1 || user.admin)) {
      // show a link to the requested accounts creation page if there are any
      if (course.requestedAccounts && course.account_requests_enabled) {
        const requestedAccountsLink = `/requested_accounts/${course.slug}`;
        controls.push((
          <p key="requested_accounts"><a href={requestedAccountsLink} className="button">{I18n.t('courses.requested_accounts')}</a></p>
        ));
      // show a button to enable new account requests, if it's not enabled already
    } else if (!course.account_requests_enabled) {
        controls.push((
          <p key="enable_account_requests"><button onClick={this.enableRequests} className="button">{I18n.t('courses.enable_account_requests')}</button></p>
        ));
      }
    }

    // If the user is an instructor or admin, and the course is published, show a stats download button
    // Always show the stats download for published non-Wiki Ed courses.
    if ((user.role === 1 || user.admin || !Features.wikiEd) && course.published) {
      controls.push((
        <p key="download_course_stats"><CourseStatsDownloadModal course={course} /></p>
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
          <GreetStudentsButton course={course} current_user={this.props.current_user} />
          {controls}
          <SalesforceLink course={course} current_user={this.props.current_user} />
        </div>
      </div>
    );
  }
}
);

const mapDispatchToProps = { initiateConfirm, addNotification, enableAccountRequests, enableForCourse };

export default connect(null, mapDispatchToProps)(AvailableActions);
