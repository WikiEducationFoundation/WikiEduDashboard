import React, { useCallback, useState, useEffect, useMemo } from 'react';
import PropTypes from 'prop-types';
import CreatableInput from '../../common/creatable_input.jsx';
import { connect } from 'react-redux';
import { upgradeSpecialUser } from '../../../actions/settings_actions';
import TextInput from '../../common/text_input';
import selectStyles from '../../../styles/single_select';

const AddSpecialUserForm = ({ submittingNewSpecialUser, upgradeSpecialUser: upgradeUser, handlePopoverClose }) => {
  const [state, setState] = useState({
    confirming: false,
    enabled: false,
    selectedOption: null,
    username: '',
    position: '',
    confirmMessage: '',
  });

  useEffect(() => {
    if (!submittingNewSpecialUser) {
      reset();
    }
  }, [submittingNewSpecialUser]);

  const reset = useCallback(() => {
    setState(prevState => ({ ...prevState, username: '', confirming: false }));
  }, []);

  const handleUsernameChange = useCallback((_key, value) => {
    setState(prevState => ({ ...prevState, username: value }));
  }, []);

  const handlePositionChange = useCallback((e) => {
    const enabled = !!e.value;
    setState(prevState => ({ ...prevState, position: e.value, enabled, selectedOption: e.value }));
  }, []);

  const handleConfirm = useCallback((e) => {
    upgradeUser(state.username, state.position);
    handlePopoverClose(e);
  }, [upgradeUser, state.username, state.position, handlePopoverClose]);

  const handleSubmit = useCallback((e) => {
    e.preventDefault();
    const { username } = state;
    setState(prevState => ({
      ...prevState,
      confirming: true,
      confirmMessage: `${I18n.t('settings.special_users.new.confirm_add_special_user')} ${username}?`
    }));
  }, [state.username]);

  const options = useMemo(() => [
    { value: 'communications_manager', label: 'communications_manager' },
    { value: 'classroom_program_manager', label: 'classroom_program_manager' },
    { value: 'outreach_manager', label: 'outreach_manager' },
    { value: 'wikipedia_experts', label: 'wikipedia_experts' },
    { value: 'technical_help_staff', label: 'technical_help_staff' },
    { value: 'survey_alerts_recipient', label: 'survey_alerts_recipient' },
    { value: 'backup_account_creator', label: 'backup_account_creator' },
  ], []);
  return (
    <tr>
      <td>
        {state.confirming ? (
          <>
            <TextInput
              id="confirm_special_user"
              onChange={handleUsernameChange}
              value={state.username}
              value_key="confirm_special_user"
              type="text"
              label={I18n.t('settings.special_users.new.form_label')}
              placeholder={I18n.t('application.submit')}
            />
            {submittingNewSpecialUser ? (
              <div className="loading__spinner" />
            ) : (
              <button
                onClick={handleConfirm}
                className="button border"
                value="confirm"
              >
                {I18n.t('settings.special_users.new.confirm_add_special_user')}
              </button>
            )}
          </>
        ) : (
          <form onSubmit={handleSubmit}>
            <TextInput
              id="new_special_user"
              onChange={handleUsernameChange}
              value={state.username}
              value_key="new_special_user"
              editable
              required
              type="text"
              label={I18n.t('settings.special_users.new.form_label')}
              placeholder={I18n.t('settings.special_users.new.form_placeholder')}
            />
            <div className="selectPosition">
              <CreatableInput
                id="specialUserPosition"
                placeholder={'Select the position'}
                onChange={handlePositionChange}
                options={options}
                styles={selectStyles}
              />
            </div>
            <button
              className={state.enabled ? 'button border' : 'button border disabled'}
              type="submit"
              value="Submit"
            >
              {I18n.t('application.submit')}
            </button>
          </form>
        )}
      </td>
    </tr>
  );
};

AddSpecialUserForm.propTypes = {
  submittingNewSpecialUser: PropTypes.bool,
  upgradeSpecialUser: PropTypes.func,
  handlePopoverClose: PropTypes.func,
};

const mapStateToProps = state => ({
  submittingNewSpecialUser: state.settings.submittingNewSpecialUser,
});

const mapDispatchToProps = {
  upgradeSpecialUser
};

export default connect(mapStateToProps, mapDispatchToProps)(AddSpecialUserForm);
