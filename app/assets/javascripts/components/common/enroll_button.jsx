import React from 'react';
import createReactClass from 'create-react-class';
import PropTypes from 'prop-types';
import { connect } from 'react-redux';
import withRouter from '../util/withRouter';

import PopoverExpandable from '../high_order/popover_expandable.jsx';
import Popover from './popover.jsx';
import Conditional from '../high_order/conditional.jsx';
import CourseUtils from '../../utils/course_utils.js';
import { addNotification } from '../../actions/notification_actions.js';
import { initiateConfirm } from '../../actions/confirm_actions';
import { getFiltered } from '../../utils/model_utils';
import { addUser, removeUser } from '../../actions/user_actions';

const EnrollButton = createReactClass({
  displayName: 'EnrollButton',

  propTypes: {
    role: PropTypes.number,
    course_id: PropTypes.string,
    match: PropTypes.object,
    users: PropTypes.array,
    course: PropTypes.object,
    allowed: PropTypes.bool,
    inline: PropTypes.bool,
    open: PropTypes.func,
    is_open: PropTypes.bool,
    current_user: PropTypes.object,
    initiateConfirm: PropTypes.func
  },

  getInitialState() {
    return ({
      onConfirm: null,
      confirmMessage: null
    });
  },

  componentDidUpdate() {
    // This handles an added user showing up after being successfully added
    if (!this.refs.username || !this.refs.username.value) { return; }
    const username = this.refs.username.value;
    if (getFiltered(this.props.users, { username, role: this.props.role }).length > 0) {
      this.props.addNotification({
        message: I18n.t('users.enrolled_success', { username }),
        closable: true,
        type: 'success'
      });
      this.refs.username.value = '';
    }
  },

  getKey() {
    return `add_user_role_${this.props.role}`;
  },

  enroll(e) {
    e.preventDefault();
    const username = this.refs.username.value;
    if (!username) { return; }
    const courseId = this.props.course_id;
    // Optional fields
    let realName;
    let roleDescription;
    if (this.refs.real_name && this.refs.role_description) {
      realName = this.refs.real_name.value;
      roleDescription = this.refs.role_description.value;
    }

    const userObject = {
      username,
      role: this.props.role,
      role_description: roleDescription,
      real_name: realName
    };

    const addUserAction = this.props.addUser;
    const onConfirm = function () {
      // Post the new user enrollment to the server
      addUserAction(courseId, { user: userObject });
    };
    const confirmMessage = I18n.t('users.enroll_confirmation', { username });

    // If the user is not already enrolled
    if (getFiltered(this.props.users, { username, role: this.props.role }).length === 0) {
      return this.props.initiateConfirm({ confirmMessage, onConfirm });
    }
    // If the user us already enrolled
    return this.props.addNotification({
      message: I18n.t('users.already_enrolled'),
      closable: true,
      type: 'error'
    });
  },

  unenroll(userId) {
    const user = getFiltered(this.props.users, { id: userId, role: this.props.role })[0];
    const courseId = this.props.course_id;
    const userObject = { user_id: userId, role: this.props.role };
    const removeUserAction = this.props.removeUser;

    const onConfirm = function () {
      // Post the user deletion request to the server
      removeUserAction(courseId, { user: userObject });
    };
    const confirmMessage = I18n.t('users.remove_confirmation', { username: user.username });
    return this.props.initiateConfirm({ confirmMessage, onConfirm });
  },

  stop(e) {
    return e.stopPropagation();
  },

  _courseLinkParams() {
    return `/courses/${this.props.router.params.course_school}/${this.props.router.params.course_title}`;
  },

  render() {
    const users = this.props.users.map((user) => {
      let removeButton;
      if (this.props.role !== 1 || this.props.users.length >= 2 || this.props.current_user.admin) {
        removeButton = (
          <button className="button border plus" aria-label="Remove user" onClick={this.unenroll.bind(this, user.id)}>-</button>
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
      let requestedAccountsLink;
      if (!Features.wikiEd) {
        const massEnrollmentUrl = `/mass_enrollment/${this.props.course.slug}`;
        massEnrollmentLink = <p><a href={massEnrollmentUrl}>Add multiple users at once.</a></p>;
      }
      if (!Features.wikiEd) {
        const requestedAccountsUrl = `/requested_accounts/${this.props.course.slug}`;
        requestedAccountsLink = <p key="requested_accounts"><a href={requestedAccountsUrl}>{I18n.t('courses.requested_accounts')}</a></p>;
      }

      editRows.push(
        <tr className="edit" key="enroll_students">
          <td>
            <p>{I18n.t('users.course_passcode')}&nbsp;<b>{this.props.course.passcode}</b></p>
            <p>{I18n.t('users.enroll_url')}</p>
            <input type="text" readOnly={true} value={enrollUrl} style={{ width: '100%' }} />
            {massEnrollmentLink}
            {requestedAccountsLink}
          </td>
        </tr>
      );
    }

    // This row allows permitted users to add usrs to the course by username
    // @props.role controls its presence in the Enrollment popup on /students
    // @props.allowed controls its presence in Edit Details mode on Overview
    if (this.props.role === 0 || this.props.allowed) {
      // Instructor-specific extra fields
      let realNameInput;
      let roleDescriptionInput;
      if (this.props.role === 1) {
        realNameInput = <input type="text" ref="real_name" placeholder={I18n.t('users.name')} />;
        roleDescriptionInput = <input type="text" ref="role_description" placeholder={I18n.t('users.role.description')} />;
      }

      editRows.push(
        <tr className="edit" key="add_students">
          <td>
            <form onSubmit={this.enroll}>
              <input type="text" ref="username" placeholder={I18n.t('users.username_placeholder')} />
              {realNameInput}
              {roleDescriptionInput}
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
    const button = (
      <button
        className={buttonClass}
        onClick={() => {
          this.props.open();
          setTimeout(() => {
            this.refs.username.focus();
          }, 125);
        }}
      >
        {buttonText}
      </button>
    );

    return (
      <div className="pop__container" onClick={this.stop}>
        {button}
        <Popover
          is_open={this.props.is_open}
          edit_row={editRows}
          rows={users}
        />
      </div>
    );
  }
}
);

const mapDispatchToProps = { initiateConfirm, addNotification, addUser, removeUser };

export default withRouter(connect(null, mapDispatchToProps)(
  Conditional(PopoverExpandable(EnrollButton))
));
