import PropTypes from 'prop-types';
import React, { useState } from 'react';
import TextInput from '../../common/text_input';

const SalesforceCredentialsForm = ({ updateSalesforceCredentials, handlePopoverClose }) => {
  const [password, setPassword] = useState('');
  const [token, setToken] = useState('');
  const handlePasswordChange = (_key, value) => {
    return setPassword(value);
  };
  const handleTokenChange = (_key, value) => {
    return setToken(value);
  };
  const handleSubmit = (e) => {
    e.preventDefault();
    updateSalesforceCredentials(password, token);
    handlePopoverClose(e);
  };

  return (
    <tr>
      <td>
        <form onSubmit={handleSubmit}>
          <TextInput
            id="salesforce_password"
            editable
            onChange={handlePasswordChange}
            value={password}
            value_key="salesforce_password"
            type="password"
            label="Password"
          />
          <TextInput
            id="salesforce_token"
            editable
            onChange={handleTokenChange}
            value={token}
            value_key="salesforce_token"
            type="password"
            label="Security Token"
          />
          <button className="button border" type="submit" value="Submit">{I18n.t('application.submit')}</button>
        </form>
      </td>
    </tr>
  );
};

SalesforceCredentialsForm.propTypes = {
  updateSalesforceCredentials: PropTypes.func,
  handlePopoverClose: PropTypes.func,
};

export default SalesforceCredentialsForm;
