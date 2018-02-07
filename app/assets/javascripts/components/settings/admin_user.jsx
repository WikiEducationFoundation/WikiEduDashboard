import React from 'react';
import { connect } from "react-redux";
import { downgradeAdmin } from '../../actions/settings_actions';

class AdminUser extends React.Component {
  constructor() {
    super();
    this.handleRevoke = this.handleRevoke.bind(this);
    this.isRevoking = this.isRevoking.bind(this);
    this.render = this.render.bind(this);
  }

  handleRevoke() {
    if (!this.isRevoking()) {
      // only process if not currently revoking
      this.props.downgradeAdmin(this.props.user.username);
    }
  }

  isRevoking() {
    const { user, revokingAdmin } = this.props;
    return revokingAdmin.status && revokingAdmin.username === user.username;
  }

  render() {
    const { user } = this.props;
    const adminLevel = user.permissions === 3 ?
      'Super Admin' :
      'Admin';

    let buttonText;
    let buttonClass = 'button';
    if (this.isRevoking()) {
      // disable button and render different text
      buttonText = I18n.t('settings.admin_users.remove.revoking_button_working');
      buttonClass += ' border';
    } else {
      buttonText = I18n.t('settings.admin_users.remove.revoke_button');
      buttonClass += ' dark';
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
              onClick={this.handleRevoke}
            >
              {buttonText}
            </button>
          </p>

        </td>

      </tr>
    );
  }
}

const mapStateToProps = state => ({
  revokingAdmin: state.settings.revokingAdmin,
});

const mapDispatchToProps = {
  downgradeAdmin,
};

export default connect(mapStateToProps, mapDispatchToProps)(AdminUser);
