import React from 'react';
import PropTypes from 'prop-types';
import { connect } from 'react-redux';
import withRouter from '../../../../util/withRouter';

// Components
import PopoverExpandable from '@components/high_order/popover_expandable.jsx';
import Popover from '@components/common/popover.jsx';
import Conditional from '@components/high_order/conditional.jsx';

import CourseUtils from '~/app/assets/javascripts/utils/course_utils.js';
import { addNotification } from '~/app/assets/javascripts/actions/notification_actions.js';
import { initiateConfirm } from '~/app/assets/javascripts/actions/confirm_actions';
import { getFiltered } from '~/app/assets/javascripts/utils/model_utils';
import { addUser, removeUser } from '~/app/assets/javascripts/actions/user_actions';

export class EnrollButton extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      onConfirm: null,
      confirmMessage: null
    };

    this.getKey = this.getKey.bind(this);
    this.enroll = this.enroll.bind(this);
    this.unenroll = this.unenroll.bind(this);
    this.stop = this.stop.bind(this);
    this._courseLinkParams = this._courseLinkParams.bind(this);
  }

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
      return this.refs.username.value = '';
    }
  }

  getKey() {
    return `add_user_role_${this.props.role}`;
  }

  enroll(e) {
    e.preventDefault();
    const username = this.refs.username.value;
    if (!username) { return; }
    const courseId = this.props.course.slug;
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
  }

  unenroll(userId) {
    const user = getFiltered(this.props.users, { id: userId, role: this.props.role })[0];
    const courseId = this.props.course.slug;
    const userObject = { user_id: userId, role: this.props.role };
    const removeUserAction = this.props.removeUser;

    const onConfirm = function () {
      // Post the user deletion request to the server
      removeUserAction(courseId, { user: userObject });
    };
    const confirmMessage = I18n.t('users.remove_confirmation', { username: user.username });
    return this.props.initiateConfirm({ confirmMessage, onConfirm });
  }

  stop(e) {
    return e.stopPropagation();
  }

  _courseLinkParams() {
    return `/courses/${this.props.router.params.course_school}/${this.props.router.params.course_title}`;
  }

  render() {
    // Disable the button for courses controlled by Wikimedia Event Center
    if (this.props.course.flags.event_sync) { return null; }

    const users = this.props.users.map((user) => {
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

EnrollButton.propTypes = {
  allowed: PropTypes.bool.isRequired,
  course: PropTypes.shape({
    passcode: PropTypes.string.isRequired,
    slug: PropTypes.string.isRequired,
    string_prefix: PropTypes.string.isRequired
  }).isRequired,
  current_user: PropTypes.shape({
    admin: PropTypes.bool.isRequired
  }).isRequired,
  role: PropTypes.number.isRequired,
  users: PropTypes.arrayOf(PropTypes.shape({
    id: PropTypes.number.isRequired,
    username: PropTypes.string.isRequired,
    role: PropTypes.number.isRequired
  })).isRequired,

  initiateConfirm: PropTypes.func.isRequired,
  addNotification: PropTypes.func.isRequired,
  addUser: PropTypes.func.isRequired,
  removeUser: PropTypes.func.isRequired,
};

const mapDispatchToProps = { initiateConfirm, addNotification, addUser, removeUser };

export default withRouter(connect(null, mapDispatchToProps)(
  Conditional(PopoverExpandable(EnrollButton))
));
