import createReactClass from 'create-react-class';
import PropTypes from 'prop-types';
import React from 'react';
import TextInput from '../../common/text_input';

const SalesforceCredentialsForm = createReactClass({
  propTypes: {
    updateSalesforceCredentials: PropTypes.func,
    handlePopoverClose: PropTypes.func,
  },

  getInitialState() {
    return {};
  },

  handleChange(key, value) {
    return this.setState({ [key]: value });
  },

  handleSubmit(e) {
    e.preventDefault();
    this.props.updateSalesforceCredentials(this.state.salesforce_password, this.state.salesforce_token);
    this.props.handlePopoverClose(e);
  },

  render() {
    return (
      <tr>
        <td>
          <form onSubmit={this.handleSubmit}>
            <TextInput
              id="salesforce_password"
              editable
              onChange={this.handleChange}
              value={this.state.salesforce_password}
              value_key="salesforce_password"
              type="password"
              label="Password"
            />
            <TextInput
              id="salesforce_token"
              editable
              onChange={this.handleChange}
              value={this.state.salesforce_token}
              value_key="salesforce_token"
              type="password"
              label="Security Token"
            />
            <button className="button border" type="submit" value="Submit">{I18n.t('application.submit')}</button>
          </form>
        </td>
      </tr>
    );
  }
});

export default SalesforceCredentialsForm;
