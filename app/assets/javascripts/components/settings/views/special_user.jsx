import createReactClass from 'create-react-class';
import PropTypes from 'prop-types';
import React from 'react';
import { connect } from 'react-redux';
import { downgradeSpecialUser } from '../../../actions/settings_actions';

const SpecialUser = createReactClass({
  propTypes: {
    downgradeSpecialUser: PropTypes.func,
    position: PropTypes.string,
    username: PropTypes.string,
    realname: PropTypes.string
  },

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
        this.props.downgradeSpecialUser(this.props.username, this.props.position);
      }
      this.setState({ confirming: false });
    } else {
      this.setState({ confirming: true });
    }
  },

  isRevoking() {
    const { username, revokingSpecialUser } = this.props;
    return revokingSpecialUser.status && revokingSpecialUser.username === username;
  },

  render() {
    const username = this.props.username || 'Not Defined';
    const realname = this.props.realname || 'Not Defined';

    let buttonText;
    let buttonClass = 'button';
    switch (this.getButtonState()) {
      case 'confirming':
        buttonClass += ' danger';
        buttonText = I18n.t('settings.special_users.remove.revoke_button_confirm', { username: this.props.username });
        break;
      case 'revoking':
        buttonText = I18n.t('settings.special_users.remove.revoking_button_working');
        buttonClass += ' border';
        break;
      default:
        // not confirming
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
          <p>{this.props.position}</p>
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

const mapStateToProps = state => ({
  revokingSpecialUser: state.settings.revokingSpecialUser,
});

const mapDispatchToProps = {
  downgradeSpecialUser,
};

export default connect(mapStateToProps, mapDispatchToProps)(SpecialUser);

