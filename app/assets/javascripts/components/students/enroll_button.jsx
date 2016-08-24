import React from 'react';
import Expandable from '../high_order/expandable.jsx';
import Popover from '../common/popover.jsx';
import ServerActions from '../../actions/server_actions.js';
import UserStore from '../../stores/user_store.js';
import Conditional from '../high_order/conditional.jsx';
import CourseUtils from '../../utils/course_utils.js';

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
    is_open: React.PropTypes.bool
  },

  mixins: [UserStore.mixin],

  getKey() {
    return `add_user_role_${this.props.role}`;
  },

  storeDidChange() {
    if (!this.refs.username) { return; }
    const username = this.refs.username.value;
    if (UserStore.getFiltered({ username, role: this.props.role }).length > 0) {
      // DEPRECATED: "Invoking 'alert()' during microtask execution is deprecated and will be removed in M53, around September 2016. See https://www.chromestatus.com/features/5647113010544640 for more details."
      alert(I18n.t('users.enrolled_success', username));
      return this.refs.username.value = '';
    }
  },

  enroll(e) {
    e.preventDefault();
    const username = this.refs.username.value;
    const userObject = { username, role: this.props.role };
    if (UserStore.getFiltered({ username, role: this.props.role }).length === 0 && confirm(I18n.t('users.enroll_confirmation', username))) {
      return ServerActions.add('user', this.props.course_id, { user: userObject });
    }
    return alert(I18n.t('users.already_enrolled'));
  },

  unenroll(userId) {
    const user = UserStore.getFiltered({ id: userId, role: this.props.role })[0];
    const userObject = { user_id: userId, role: this.props.role };
    if (confirm(I18n.t('users.remove_confirmation', { username: user.username }))) {
      return ServerActions.remove('user', this.props.course_id, { user: userObject });
    }
  },
  stop(e) {
    return e.stopPropagation();
  },

  _courseLinkParams() {
    return `/courses/${this.props.params.course_school}/${this.props.params.course_title}`;
  },

  render() {
    let users = this.props.users.map(user => {
      let removeButton;
      if (this.props.role !== 1 || this.props.users.length >= 2) {
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
    let enrollUrl = window.location.origin + this._courseLinkParams() + enrollParam + this.props.course.passcode;

    let editRows = [];
    if (this.props.role === 0) {
      editRows.push(
        <tr className="edit" key="enroll_students">
          <td>
            <p>{I18n.t('users.course_passcode')}<b>{this.props.course.passcode}</b></p>
            <p>{I18n.t('users.enroll_url')}</p>
            <input type="text" readOnly={true} value={enrollUrl} style={{ width: '100%' }} />
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
    let buttonText = this.props.inline ? '+' : CourseUtils.i18n('enrollment', this.props.course.string_prefix);

    // Remove this check when we re-enable adding users by username
    let button = <button className={buttonClass} onClick={this.props.open}>{buttonText}</button>;

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

export default Conditional(Expandable(EnrollButton));
