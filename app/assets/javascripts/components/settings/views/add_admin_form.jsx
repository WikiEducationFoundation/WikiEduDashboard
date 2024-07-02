import React, { useState, useEffect } from 'react';
import PropTypes from 'prop-types';
import TextInput from '../../common/text_input';

const AddAdminForm = ({ submittingNewAdmin, upgradeAdmin, handlePopoverClose }) => {
  const [confirming, setConfirming] = useState(false);
  const [username, setUsername] = useState('');

  useEffect(() => {
    if (!submittingNewAdmin) {
      reset();
    }
  }, [submittingNewAdmin]);

  const handleUsernameChange = (_key, value) => {
    setUsername(value);
  };

  const reset = () => {
    setUsername('');
    setConfirming(false);
  };

  const handleConfirm = (e) => {
    upgradeAdmin(username);
    handlePopoverClose(e);
  };

  const handleSubmit = (e) => {
    e.preventDefault();
    setConfirming(true);
  };

  const renderForm = () => (
    <tr>
      <td>
        <form onSubmit={handleSubmit}>
          <TextInput
            id="new_admin_name"
            onChange={handleUsernameChange}
            value={username}
            value_key="new_admin_name"
            editable
            required
            type="text"
            label={I18n.t('settings.admin_users.new.form_label')}
            placeholder={I18n.t('settings.admin_users.new.form_placeholder')}
          />
          <button className="button border" type="submit" value="Submit">{I18n.t('application.submit')}</button>
        </form>
      </td>
    </tr>
  );

  const renderConfirm = () => {
    let buttonContent;
    if (submittingNewAdmin) {
      buttonContent = (<div className="loading__spinner" />);
    } else {
      buttonContent = (
        <button
          onClick={handleConfirm}
          className="button border"
          value="confirm"
        >
          {I18n.t('settings.admin_users.new.confirm_add_admin')}
        </button>
      );
    }
    return (
      <tr>
        <td>
          <TextInput
            id="new_admin_name"
            onChange={handleUsernameChange}
            value={username}
            value_key="new_admin_name"
            type="text"
            label={I18n.t('settings.admin_users.new.form_label')}
            placeholder={I18n.t('application.submit')}
          />
          {buttonContent}
        </td>
      </tr>
    );
  };

  return confirming ? renderConfirm() : renderForm();
};

AddAdminForm.propTypes = {
  submittingNewAdmin: PropTypes.bool,
  upgradeAdmin: PropTypes.func.isRequired,
  handlePopoverClose: PropTypes.func.isRequired,
};

export default AddAdminForm;
