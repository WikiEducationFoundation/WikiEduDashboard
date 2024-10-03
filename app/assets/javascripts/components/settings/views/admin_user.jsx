import createReactClass from 'create-react-class';
import PropTypes from 'prop-types';
import React from 'react';

const AdminUser = createReactClass({
  propTypes: {
    downgradeAdmin: PropTypes.func,
    user: PropTypes.shape({
      id: PropTypes.number,
      username: PropTypes.string.isRequired,
      real_name: PropTypes.string,
      permissions: PropTypes.number.isRequired,
    }),
  },

  // eslint-disable-next-line object-shorthand
  getInitialState: function () {
    return { confirming: false };
  },

  /*
    returns the current state of the revoking button
    1) "not confirming"
    2) "confirming"
    3) "submitting"
  */
  getButtonState() {
    if (this.isRevoking()) {
      return 'revoking';
    } else if (this.state.confirming) {
      return 'confirming';
    }
    return 'not confirming';
  },

  handleClick() {
    if (this.state.confirming) {
      // user has clicked button while confirming. Process!
      if (!this.isRevoking()) {
        // only process if not currently revoking
        this.props.downgradeAdmin(this.props.user.username);
      }
      this.setState({ confirming: false });
    } else {
      this.setState({ confirming: true });
    }
  },

  isRevoking() {
    const { user, revokingAdmin } = this.props;
    return revokingAdmin.status && revokingAdmin.username === user.username;
  },

  render() {
    const { user } = this.props;
    const adminLevel = user.permissions === 3
      ? 'Super Admin'
      : 'Admin';

    let buttonText;
    let buttonClass = 'button';
    switch (this.getButtonState()) {
      case 'confirming':
        buttonClass += ' danger';
        buttonText = I18n.t('settings.admin_users.remove.revoke_button_confirm', { username: user.username });
        break;
      case 'revoking':
        buttonText = I18n.t('settings.admin_users.remove.revoking_button_working');
        buttonClass += ' border';
        break;
      default:
        // not confirming
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
              onClick={this.handleClick}
            >
              {buttonText}
            </button>
          </p>

        </td>

      </tr>
    );
  },
});

export default AdminUser;
