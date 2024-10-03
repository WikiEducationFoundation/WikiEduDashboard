import React, { useState } from 'react';
import PropTypes from 'prop-types';
import { connect } from 'react-redux';
import { downgradeSpecialUser as downgradeUserAction } from '../../../actions/settings_actions'; // Importing and renaming the action creator

const SpecialUser = ({
  downgradeSpecialUser, // Prop for downgrading special user (renamed from action creator)
  position,
  username = 'Not Defined',
  realname = 'Not Defined',
  revokingSpecialUser,
}) => {
  const [confirming, setConfirming] = useState(false);

  // Function to check if currently revoking
  const isRevoking = () => {
    return (
      revokingSpecialUser.status && revokingSpecialUser.username === username
    );
  };

  // Function to determine the current state of the button
  const getButtonState = () => {
    if (isRevoking()) {
      return 'revoking';
    } else if (confirming) {
      return 'confirming';
    }
    return 'not confirming';
  };

  // Handler for button click
  const handleClick = () => {
    if (confirming) {
      // User has clicked button while confirming. Process!
      if (!isRevoking()) {
        // Only process if not currently revoking
        downgradeSpecialUser(username, position); // Using the prop to call the action creator
      }
      setConfirming(false);
    } else {
      setConfirming(true);
    }
  };

  let buttonText;
  let buttonClass = 'button';

  // Determine button text and class based on button state
  switch (getButtonState()) {
    case 'confirming':
      buttonClass += ' danger';
      buttonText = I18n.t(
        'settings.special_users.remove.revoke_button_confirm',
        { username }
      );
      break;
    case 'revoking':
      buttonText = I18n.t(
        'settings.special_users.remove.revoking_button_working'
      );
      buttonClass += ' border';
      break;
    default:
      // Not confirming
      buttonClass += ' danger';
      buttonText = I18n.t('settings.special_users.remove.revoke_button');
      break;
  }

  return (
    <tr className="user">
      <td className="user__real_name">
        <p>{username}</p>
      </td>
      <td className="user__real_name">
        <p>{realname}</p>
      </td>
      <td className="user__position">
        <p>{position}</p>
      </td>
      <td className="user__revoke">
        <p>
          <button className={buttonClass} onClick={handleClick}>
            {buttonText}
          </button>
        </p>
      </td>
    </tr>
  );
};

// Prop type validation
SpecialUser.propTypes = {
  downgradeSpecialUser: PropTypes.func,
  position: PropTypes.string,
  username: PropTypes.string,
  realname: PropTypes.string,
  revokingSpecialUser: PropTypes.shape({
    status: PropTypes.bool,
    username: PropTypes.string,
  }),
};

// Mapping state to props
const mapStateToProps = state => ({
  revokingSpecialUser: state.settings.revokingSpecialUser,
});

// Mapping actions to props
const mapDispatchToProps = {
  downgradeSpecialUser: downgradeUserAction, // Connecting the renamed action creator
};

// Connecting component to Redux store
export default connect(mapStateToProps, mapDispatchToProps)(SpecialUser);
