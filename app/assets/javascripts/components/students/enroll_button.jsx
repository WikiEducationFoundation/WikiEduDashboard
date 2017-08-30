import React from 'react';
import PopoverExpandable from '../high_order/popover_expandable.jsx';
import Popover from '../common/popover.jsx';
import ServerActions from '../../actions/server_actions.js';
import UserStore from '../../stores/user_store.js';
import Conditional from '../high_order/conditional.jsx';
import CourseUtils from '../../utils/course_utils.js';
import NotificationActions from '../../actions/notification_actions.js';
import Confirm from '../common/confirm.jsx';
import ConfirmActions from '../../actions/confirm_actions.js';
import ConfirmationStore from '../../stores/confirmation_store.js';

const EnrollButton = React.createClass({
  displayName: 'EnrollButton',

  propTypes: {
    role: React.PropTypes.number,
    course_id: React.PropTypes.string,
    params: React.PropTypes.object,
    users: React.PropTypes.array,
    course: React.PropTypes.object,
    allowed: React.PropTypes.bool,
    inline: React.PropTypes.bool,
    open: React.PropTypes.func,
    is_open: React.PropTypes.bool,
    right_aligned: React.PropTypes.bool,
    current_user: React.PropTypes.object
  },

  mixins: [UserStore.mixin, ConfirmationStore.mixin],

  getInitialState() {
    return ({
      showConfirm: false,
      onConfirm: null,
      onCancel: null,
      confirmMessage: null
    });
  },

  getKey() {
    return `add_user_role_${this.props.role}`;
  },

  storeDidChange() {
    // This handles closing the Confirm dialog after it has been clicked.
    if (!ConfirmationStore.isConfirmationActive()) {
      this.setState(this.getInitialState());
    }

    // This handles an added user showing up in the UserStore
    if (!this.refs.username) { return; }
    const username = this.refs.username.value;
    if (UserStore.getFiltered({ username, role: this.props.role }).length > 0) {
      NotificationActions.addNotification({
        message: I18n.t('users.enrolled_success', { username }),
        closable: true,
        type: 'success'
      });
      return this.refs.username.value = '';
    }
  },

  enroll(e) {
    e.preventDefault();
    const username = this.refs.username.value;
    if (!username) { return; }
    const courseId = this.props.course_id;
    const userObject = { username, role: this.props.role };

    const onConfirm = function () {
      // Post the new user to the server
      ServerActions.add('user', courseId, { user: userObject });
      // Send the confirm signal
      return ConfirmActions.actionConfirmed();
    };
    const onCancel = function () {
      return ConfirmActions.actionCancelled();
    };
    const confirmMessage = I18n.t('users.enroll_confirmation', { username });

    // If the user is not already enrolled
    if (UserStore.getFiltered({ username, role: this.props.role }).length === 0) {
      ConfirmActions.confirmationInitiated();
      return this.setState({ onConfirm, onCancel, confirmMessage, showConfirm: true });
    }
    // If the user us already enrolled
    return NotificationActions.addNotification({
      message: I18n.t('users.already_enrolled'),
      closable: true,
      type: 'error'
    });
  },

  unenroll(userId) {
    const user = UserStore.getFiltered({ id: userId, role: this.props.role })[0];
    const courseId = this.props.course_id;
    const userObject = { user_id: userId, role: this.props.role };

    const onConfirm = function () {
      // Post the new user to the server
      ServerActions.remove('user', courseId, { user: userObject });
      // Send the confirm signal
      return ConfirmActions.actionConfirmed();
    };
    const onCancel = function () {
      return ConfirmActions.actionCancelled();
    };
    const confirmMessage = I18n.t('users.remove_confirmation', { username: user.username });
    this.setState({ onConfirm, onCancel, confirmMessage, showConfirm: true });
  },

  stop(e) {
    return e.stopPropagation();
  },

  _courseLinkParams() {
    return `/courses/${this.props.params.course_school}/${this.props.params.course_title}`;
  },

  render() {
    let confirmationDialog;
    if (this.state.showConfirm) {
      confirmationDialog = (
        <Confirm
          onConfirm={this.state.onConfirm}
          onCancel={this.state.onCancel}
          message={this.state.confirmMessage}
        />
      );
    }

    const users = this.props.users.map(user => {
      let removeButton;
      if (this.props.role !== 1 || this.props.users.length >= 2 || this.props.current_user.admin) {
        removeButton = (
          <button className="button border plus" onClick={this.unenroll.bind(this, user.id)}>-</button>
        );
      }
      return (
        <tr key={`${user.id}_enrollment`}>
          <td>{user.username}{removeButton}</td>
        </tr>
      );
    });

    const enrollParam = '?enroll=';
    const enrollUrl = window.location.origin + this._courseLinkParams() + enrollParam + this.props.course.passcode;

    const editRows = [];


    if (this.props.role === 0) {
      let massEnrollmentLink;
      if (!Features.wikiEd) {
        const massEnrollmentUrl = `/mass_enrollment/${this.props.course.slug}`;
        massEnrollmentLink = <p><a href={massEnrollmentUrl}>Add multiple users at once.</a></p>;
      }

      editRows.push(
        <tr className="edit" key="enroll_students">
          <td>
            <p>{I18n.t('users.course_passcode')}<b>{this.props.course.passcode}</b></p>
            <p>{I18n.t('users.enroll_url')}</p>
            <input type="text" readOnly={true} value={enrollUrl} style={{ width: '100%' }} />
            {massEnrollmentLink}
          </td>
        </tr>
      );
    }

    // This row allows permitted users to add usrs to the course by username
    // @props.role controls its presence in the Enrollment popup on /students
    // @props.allowed controls its presence in Edit Details mode on Overview
    if (this.props.role === 0 || this.props.allowed) {
      editRows.push(
        <tr className="edit" key="add_students">
          <td>
            <form onSubmit={this.enroll}>
              <input type="text" ref="username" placeholder={I18n.t('users.username_placeholder')} />
              <button className="button border" type="submit">{CourseUtils.i18n('enroll', this.props.course.string_prefix)}</button>
            </form>
          </td>
        </tr>
      );
    }

    let buttonClass = 'button';
    buttonClass += this.props.inline ? ' border plus' : ' dark';
    const buttonText = this.props.inline ? '+' : CourseUtils.i18n('enrollment', this.props.course.string_prefix);

    // Remove this check when we re-enable adding users by username
    const button = <button className={buttonClass} onClick={this.props.open}>{buttonText}</button>;

    return (
      <div className="pop__container" onClick={this.stop}>
        {confirmationDialog}
        {button}
        <Popover
          right_aligned={this.props.right_aligned}
          is_open={this.props.is_open}
          edit_row={editRows}
          rows={users}
        />
      </div>
    );
  }
}
);

export default Conditional(PopoverExpandable(EnrollButton));
