import React from 'react';
import createReactClass from 'create-react-class';
import PropTypes from 'prop-types';
import { connect } from "react-redux";

import PopoverExpandable from '../high_order/popover_expandable.jsx';
import Popover from '../common/popover.jsx';
import Conditional from '../high_order/conditional.jsx';
import CourseUtils from '../../utils/course_utils.js';
import { addNotification } from '../../actions/notification_actions.js';
import { initiateConfirm } from '../../actions/confirm_actions';
import { requestAccount } from '../../actions/new_account_actions.js';

const RequestAccountsButton = createReactClass({
  displayName: 'RequestAccountsButton',

  propTypes: {
    role: PropTypes.number,
    course_id: PropTypes.string,
    username: PropTypes.string,
    userEmail: PropTypes.string,
    requestAccount: PropTypes.func
  },

  getInitialState() {
    return ({
      onConfirm: null,
      confirmMessage: null
    });
  },

  getKey() {
    return `user_role_${this.props.role}`;
  },

  request(e) {
    e.preventDefault();
    const username = this.refs.username.value;
    const email = this.refs.userEmail.value;
    if (!username || !email) { return; }
    const coursePasscode = this.props.course.passcode;
    const course = this.props.course;
    const newAccount = {
      username,
      email
    };

    const requestNewAccount = this.props.requestAccount;
    const onConfirm = function () {
      requestNewAccount(coursePasscode, course, newAccount, true);
    };
    const confirmMessage = I18n.t('users.request_confirmation', { username });

    return this.props.initiateConfirm(confirmMessage, onConfirm);
  },

  stop(e) {
    return e.stopPropagation();
  },


  render() {
    const editRows = [];

    editRows.push(
      <tr className="edit" key="add_students">
        <td>
          <form onSubmit={this.request}>
            <input type="text" ref="username" placeholder={I18n.t('users.username_placeholder')} />
            <input type="text" ref="userEmail" placeholder={I18n.t('users.useremail_placeholder')} />
            <button className="button border" type="submit">{CourseUtils.i18n('enroll', this.props.course.string_prefix)}</button>
          </form>
        </td>
      </tr>
    );

    let buttonClass = 'button';
    buttonClass += this.props.inline ? ' border plus' : ' dark margin';
    const buttonText = this.props.inline ? '+' : CourseUtils.i18n('request_accounts', this.props.course.string_prefix);
    // Remove this check when we re-enable adding users by username
    const button = <button className={buttonClass} id="Request Accounts" onClick={this.props.open}>{buttonText}</button>;
    return (
      <div className="pop__container" onClick={this.stop}>
        {button}
        <Popover
          is_open={this.props.is_open}
          edit_row={editRows}
        />
      </div>
    );
  }
}
);

const mapDispatchToProps = { initiateConfirm, addNotification, requestAccount };

export default connect(null, mapDispatchToProps)(
  Conditional(PopoverExpandable(RequestAccountsButton))
);
