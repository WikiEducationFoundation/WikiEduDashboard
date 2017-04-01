import React from 'react';
import ServerActions from '../../actions/server_actions.js';
import ChatActions from '../../actions/chat_actions.js';
import CourseStore from '../../stores/course_store.js';
import CourseUtils from '../../utils/course_utils.js';
import CourseDateUtils from '../../utils/course_date_utils.js';
import Confirm from '../common/confirm.jsx';
import ConfirmActions from '../../actions/confirm_actions.js';
import ConfirmationStore from '../../stores/confirmation_store.js';
import SalesforceLink from './salesforce_link.jsx';

const getState = () => ({ course: CourseStore.getCourse() });

const AvailableActions = React.createClass({
  displayName: 'Actions',

  propTypes: {
    current_user: React.PropTypes.object
  },

  mixins: [CourseStore.mixin, ConfirmationStore.mixin],

  getInitialState() {
    return ({
      course: CourseStore.getCourse(),
      showConfirm: null,
      onConfirm: null,
      onCancel: null
    });
  },

  storeDidChange() {
    // This handles closing the Confirm dialog after it has been clicked.
    if (!ConfirmationStore.isConfirmationActive()) {
      this.setState(this.getInitialState());
    }
    return this.setState(getState());
  },

  join() {
    const EnrollURL = this.state.course.enroll_url;
    const onConfirm = function (passcode) {
      ConfirmActions.actionConfirmed();
      return window.location = EnrollURL + passcode;
    };
    const onCancel = function () {
      return ConfirmActions.actionCancelled();
    };
    const confirmMessage = I18n.t('courses.passcode_prompt');
    const joinDescription = CourseUtils.i18n('join_details', this.state.course.string_prefix);

    this.setState({ onConfirm, onCancel, confirmMessage, joinDescription, showConfirm: true });
  },

  leave() {
    if (confirm(I18n.t('courses.leave_confirmation'))) {
      const userObject = { user_id: this.props.current_user.id, role: 0 };
      return ServerActions.remove('user', this.state.course.slug, { user: userObject });
    }
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
    if (confirm('Are you sure you want to enable chat?')) {
      return ChatActions.enableForCourse(this.state.course.id);
    }
  },

  render() {
    const controls = [];
    const user = this.props.current_user;

    let confirmationDialog;
    if (this.state.showConfirm) {
      confirmationDialog = (
        <Confirm
          onConfirm={this.state.onConfirm}
          onCancel={this.state.onCancel}
          message={this.state.confirmMessage}
          explanation={this.state.joinDescription}
          showInput={true}
        />
      );
    }

    // If user has a role in the course or is an admin
    if ((user.role !== undefined) || user.admin) {
      // If user is a student, show the 'leave' button.
      if (user.role === 0) {
        controls.push((
          <p key="leave"><button onClick={this.leave} className="button">{CourseUtils.i18n('leave_course', this.state.course.string_prefix)}</button></p>
        ));
      }
      // If course is not published, show the 'delete' button to instructors and admins.
      if ((user.role === 1 || user.admin) && !this.state.course.published) {
        controls.push((
          <p key="delete"><button className="button danger" onClick={this.delete}>{CourseUtils.i18n('delete_course', this.state.course_string_prefix)}</button></p>
        ));
      }
      // If the course is ended, show the 'needs update' button.
      if (CourseDateUtils.isEnded(this.state.course)) {
        controls.push((
          <p key="needs_update"><button className="button" onClick={this.needsUpdate}>{I18n.t('courses.needs_update')}</button></p>
        ));
      }
      // If chat is available but not enabled for course, show the 'enable chat' button.
      if (Features.enableChat && !this.state.course.flags.enable_chat && user.admin) {
        controls.push((
          <p key="enable_chat"><button className="button" onClick={this.enableChat}>{I18n.t('courses.enable_chat')}</button></p>
        ));
      }
    // If user has no role or is logged out
    } else if (!this.state.course.ended) {
      controls.push((
        <p key="join"><button onClick={this.join} className="button">{CourseUtils.i18n('join_course', this.state.course.string_prefix)}</button></p>
      ));
    }

    // If no controls are available
    if (controls.length === 0) {
      controls.push(
        <p key="none">{I18n.t('courses.no_available_actions')}</p>
      );
    }

    return (
      <div className="module">
        <div className="section-header">
          <h3>{I18n.t('courses.actions')}</h3>
        </div>
        <div className="module__data">
          {confirmationDialog}
          {controls}
          <SalesforceLink course={this.state.course} current_user={this.props.current_user} />
        </div>
      </div>
    );
  }
}
);

export default AvailableActions;
