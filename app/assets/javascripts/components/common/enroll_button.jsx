import React, { useEffect, useRef } from 'react';
import PropTypes from 'prop-types';
import { connect } from 'react-redux';
import withRouter from '../util/withRouter.jsx';

// Components
import Popover from '@components/common/popover.jsx';
import Conditional from '@components/high_order/conditional.jsx';

import CourseUtils from '~/app/assets/javascripts/utils/course_utils.js';
import { addNotification } from '~/app/assets/javascripts/actions/notification_actions.js';
import { initiateConfirm } from '~/app/assets/javascripts/actions/confirm_actions';
import { getFiltered } from '~/app/assets/javascripts/utils/model_utils';
import { addUser, removeUser } from '~/app/assets/javascripts/actions/user_actions';
import useExpandablePopover from '../../hooks/useExpandablePopover';

const EnrollButton = (props) => {
  const usernameRef = useRef(null);
  const realNameRef = useRef(null);
  const roleDescriptionRef = useRef(null);

  useEffect(() => {
    if (!usernameRef.current || !usernameRef.current.value) { return; }
    const username = usernameRef.current.value;
    if (getFiltered(props.users, { username, role: props.role }).length > 0) {
      props.addNotification({
        message: I18n.t('users.enrolled_success', { username }),
        closable: true,
        type: 'success'
      });
      usernameRef.current.value = '';
    }
  }, [props.users]);

  const getKey = () => {
    return `add_user_role_${props.role}`;
  };

  const { isOpen, ref, open } = useExpandablePopover(getKey);

  const enroll = (e) => {
    e.preventDefault();
    const username = usernameRef.current.value;
    if (!username) { return; }
    const courseId = props.course.slug;
    // Optional fields
    let realName;
    let roleDescription;
    if (realNameRef.current && roleDescriptionRef.current) {
      realName = realNameRef.current.value;
      roleDescription = roleDescriptionRef.current.value;
    }

    const userObject = {
      username,
      role: props.role,
      role_description: roleDescription,
      real_name: realName
    };

    const addUserAction = props.addUser;
    const onConfirm = () => {
      // Post the new user enrollment to the server
      addUserAction(courseId, { user: userObject });
    };
    const confirmMessage = I18n.t('users.enroll_confirmation', { username });

    // If the user is not already enrolled
    if (getFiltered(props.users, { username, role: props.role }).length === 0) {
      return props.initiateConfirm({ confirmMessage, onConfirm });
    }
    // If the user us already enrolled
    return props.addNotification({
      message: I18n.t('users.already_enrolled'),
      closable: true,
      type: 'error'
    });
  };

  const unenroll = (userId) => {
    const user = getFiltered(props.users, { id: userId, role: props.role })[0];
    const courseId = props.course.slug;
    const userObject = { user_id: userId, role: props.role };
    const removeUserAction = props.removeUser;

    const onConfirm = () => {
      // Post the user deletion request to the server
      removeUserAction(courseId, { user: userObject });
    };
    const confirmMessage = I18n.t('users.remove_confirmation', { username: user.username });
    return props.initiateConfirm({ confirmMessage, onConfirm });
  };

  const stop = (e) => {
    return e.stopPropagation();
  };

  const _courseLinkParams = () => {
    return `/courses/${props.router.params.course_school}/${props.router.params.course_title}`;
  };

  // Disable the button for courses controlled by Wikimedia Event Center
  if (props.course.flags.event_sync) { return null; }

  const users = props.users.map((user) => {
    let removeButton;
    if (props.role !== 1 || props.users.length >= 2 || props.current_user.admin) {
      removeButton = (
        <button className="button border plus" aria-label="Remove user" onClick={() => unenroll(user.id)}>-</button>
      );
    }
    return (
      <tr key={`${user.id}_enrollment`}>
        <td>{user.username}{removeButton}</td>
      </tr>
    );
  });

  const enrollParam = '?enroll=';
  const enrollUrl = window.location.origin + _courseLinkParams() + enrollParam + props.course.passcode;

  const editRows = [];


  if (props.role === 0) {
    let massEnrollmentLink;
    let requestedAccountsLink;
    if (!Features.wikiEd) {
      const massEnrollmentUrl = `/mass_enrollment/${props.course.slug}`;
      massEnrollmentLink = <p><a href={massEnrollmentUrl}>Add multiple users at once.</a></p>;
    }
    if (!Features.wikiEd) {
      const requestedAccountsUrl = `/requested_accounts/${props.course.slug}`;
      requestedAccountsLink = <p key="requested_accounts"><a href={requestedAccountsUrl}>{I18n.t('courses.requested_accounts')}</a></p>;
    }

    editRows.push(
      <tr className="edit" key="enroll_students">
        <td>
          <p>{I18n.t('users.course_passcode')}&nbsp;<b>{props.course.passcode}</b></p>
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
  if (props.role === 0 || props.allowed) {
    // Instructor-specific extra fields
    let realNameInput;
    let roleDescriptionInput;
    if (props.role === 1) {
      realNameInput = <input type="text" ref={realNameRef} placeholder={I18n.t('users.name')} />;
      roleDescriptionInput = <input type="text" ref={roleDescriptionRef} placeholder={I18n.t('users.role.description')} />;
    }

    editRows.push(
      <tr className="edit" key="add_students">
        <td>
          <form onSubmit={enroll}>
            <input type="text" ref={usernameRef} placeholder={I18n.t('users.username_placeholder')} />
            {realNameInput}
            {roleDescriptionInput}
            <button className="button border" type="submit">{CourseUtils.i18n('enroll', props.course.string_prefix)}</button>
          </form>
        </td>
      </tr>
    );
  }

  let buttonClass = 'button';
  buttonClass += props.inline ? ' border plus' : ' dark';
  const buttonText = props.inline ? '+' : CourseUtils.i18n('enrollment', props.course.string_prefix);

  // Remove this check when we re-enable adding users by username
  const button = (
    <button
      className={buttonClass}
      onClick={() => {
        open();
        setTimeout(() => {
          usernameRef.current.focus();
        }, 125);
      }}
    >
      {buttonText}
    </button>
  );

  return (
    <div className="pop__container" onClick={stop} ref={ref}>
      {button}
      <Popover
        is_open={isOpen}
        edit_row={editRows}
        rows={users}
      />
    </div>
  );
};

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
  Conditional(EnrollButton)
));
