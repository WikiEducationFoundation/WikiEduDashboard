import React from 'react';
import { bindActionCreators } from 'redux';
import { connect } from 'react-redux';

import * as NewAccountActions from '../../actions/new_account_actions.js';
import TextInput from '../common/text_input.jsx';

const NewAccountModal = ({ course, passcode, closeModal, newAccount, actions }) => {
  const checkAvailability = () => (actions.checkAvailability(newAccount));
  const requestAccount = () => (actions.requestAccount(passcode, course, newAccount));

  let checkAvailabilityButton;
  if (!newAccount.usernameValid || !newAccount.emailValid) {
    checkAvailabilityButton = (
      <button onClick={checkAvailability} disabled={!newAccount.username || !newAccount.emailValid} className="button">
        {I18n.t('courses.new_account_check_username')}
      </button>
    );
  }
  let checkingSpinner;
  if (newAccount.checking) {
    checkingSpinner = <div className="authorship-loading"> &nbsp; &nbsp; &nbsp; </div>;
  }
  let requestAccountButton;
  if (newAccount.usernameValid && newAccount.emailValid && !newAccount.submitted) {
    requestAccountButton = (
      <button onClick={requestAccount} className="button dark">
        {I18n.t('courses.new_account_submit')}
      </button>
    );
  }
  let confirmSubmitted;
  if (newAccount.submitted) {
    confirmSubmitted = <big>{I18n.t('courses.new_account_submitted')}</big>;
  }

  return (
    <div className="basic-modal">
      <button onClick={closeModal} className="pull-right article-viewer-button icon-close"></button>
      <div>
        <p>{I18n.t('courses.new_account_info')}</p>
      </div>
      <TextInput
        id="new_account_username"
        value={newAccount.username}
        value_key="username"
        onChange={actions.setNewAccountUsername}
        required
        editable
        label={I18n.t('courses.new_account_username')}
        placeholder={I18n.t('courses.new_account_username_placeholder')}
      />
      <TextInput
        id="new_account_email"
        value={newAccount.email}
        value_key="email"
        onChange={actions.setNewAccountEmail}
        required
        editable
        label={I18n.t('courses.new_account_email')}
        placeholder={I18n.t('courses.new_account_email_placeholder')}
      />
      <div>
        {confirmSubmitted}
        <div className = "left">
          <p className="red" dangerouslySetInnerHTML={{ __html: newAccount.error }} />
          {checkingSpinner}
        </div>
        <div className="right pull-right">
          {checkAvailabilityButton}
          {requestAccountButton}
        </div>
      </div>
    </div>
  );
};

NewAccountModal.propTypes = {
  course: React.PropTypes.object,
  passcode: React.PropTypes.string,
  newAccount: React.PropTypes.object,
  closeModal: React.PropTypes.func,
  actions: React.PropTypes.object
};

const mapStateToProps = state => ({
  newAccount: state.newAccount
});

const mapDispatchToProps = dispatch => ({
  actions: bindActionCreators(NewAccountActions, dispatch)
});

export default connect(mapStateToProps, mapDispatchToProps)(NewAccountModal);
