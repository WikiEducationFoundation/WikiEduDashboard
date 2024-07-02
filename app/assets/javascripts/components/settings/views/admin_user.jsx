import React, { useState } from 'react';
import PropTypes from 'prop-types';

const AdminUser = ({ downgradeAdmin, user, revokingAdmin }) => {
  const [confirming, setConfirming] = useState(false);

  /*
    returns the current state of the revoking button
    1) "not confirming"
    2) "confirming"
    3) "submitting"
  */
  const getButtonState = () => {
    if (isRevoking()) {
      return 'revoking';
    } else if (confirming) {
      return 'confirming';
    }
    return 'not confirming';
  };

  const handleClick = () => {
    if (confirming) {
      if (!isRevoking()) {
        downgradeAdmin(user.username);
      }
      setConfirming(false);
    } else {
      setConfirming(true);
    }
  };

  const isRevoking = () => {
    return revokingAdmin.status && revokingAdmin.username === user.username;
  };

  const adminLevel = user.permissions === 3 ? 'Super Admin' : 'Admin';

  let buttonText;
  let buttonClass = 'button';
  switch (getButtonState()) {
    case 'confirming':
      buttonClass += ' danger';
      buttonText = I18n.t('settings.admin_users.remove.revoke_button_confirm', { username: user.username });
      break;
    case 'revoking':
      buttonText = I18n.t('settings.admin_users.remove.revoking_button_working');
      buttonClass += ' border';
      break;
    default:
      buttonClass += ' danger';
      buttonText = I18n.t('settings.admin_users.remove.revoke_button');
      break;
  }

  return (
    <tr className="user">
      <td className="user__username">
        <p>{user.username}</p>
      </td>
      <td className="user__real_name">
        <p>{user.real_name}</p>
      </td>
      <td className="user__adminLevel">
        <p>{adminLevel}</p>
      </td>
      <td className="user__revoke">
        <p>
          <button
            className={buttonClass}
            onClick={handleClick}
          >
            {buttonText}
          </button>
        </p>
      </td>
    </tr>
  );
};

AdminUser.propTypes = {
  downgradeAdmin: PropTypes.func.isRequired,
  user: PropTypes.shape({
    id: PropTypes.number,
    username: PropTypes.string.isRequired,
    real_name: PropTypes.string,
    permissions: PropTypes.number.isRequired,
  }).isRequired,
  revokingAdmin: PropTypes.shape({
    status: PropTypes.bool.isRequired,
    username: PropTypes.string.isRequired,
  }).isRequired,
};

export default AdminUser;
