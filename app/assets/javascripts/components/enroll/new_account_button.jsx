import React from 'react';
import createReactClass from 'create-react-class';
import PropTypes from 'prop-types';
import NewAccountModal from './new_account_modal.jsx';
import { canUserCreateAccount } from '@components/util/helpers';

const NewAccountButton = createReactClass({
  displayName: 'NewAccountButton',

  propTypes: {
    course: PropTypes.object.isRequired,
    passcode: PropTypes.string,
    currentUser: PropTypes.object.isRequired,
  },

  getInitialState() {
    return {
      showModal: false,
      disabled: false,
    };
  },

  componentDidMount() {
    canUserCreateAccount().then((canCreate) => {
      this.setState({ disabled: !canCreate });
    });
  },
  openModal() {
    this.setState({ showModal: true });
  },

  closeModal() {
    this.setState({ showModal: false });
  },

  render() {
    const { course } = this.props;
    // If account registration is not enabled for the course, just link to the signup
    // endpoint for the user to register an account on their own.
    if (!course.account_requests_enabled) {
      return (
        <>
          <a
            data-method="post"
            href={`/users/auth/mediawiki_signup?origin=${window.location}`}
            className={`button auth signup border margin ${this.state.disabled ? 'disabled' : ''}`}
            style={{
              marginRight: '0'
            }}
          >
            <i className="icon icon-wiki-logo" />
            {I18n.t('application.sign_up_extended')}
          </a>
          {this.state.disabled && (
          <div className="tooltip-trigger tooltip-small">
            <img className="info-img" src="/assets/images/info.svg" alt="tooltip default logo" />
            <div className="tooltip dark large">
              <p>
                {I18n.t('error.ip_blocked')}
              </p>
            </div>
          </div>
        )}
        </>
      );
    }

    // If register_accounts flag is set for the course, use the NewAccountButton.
    let buttonOrModal;
    if (this.state.showModal) {
      buttonOrModal = <NewAccountModal course={course} passcode={this.props.passcode} closeModal={this.closeModal} currentUser={this.props.currentUser} />;
    } else {
      buttonOrModal = (
        <button onClick={this.openModal} key="request_account" className="button auth signup border margin request_accounts">
          <i className="icon icon-wiki-logo" /> {this.props.currentUser.isInstructor ? I18n.t('application.request_account_create') : I18n.t('application.request_account')}
        </button>
      );
    }

    return buttonOrModal;
  }
});

export default NewAccountButton;
