import createReactClass from 'create-react-class';
import PropTypes from 'prop-types';
import React from 'react';
import SalesforceCredentialsForm from '../containers/salesforce_credentials_form_container';
import Popover from '../../common/popover.jsx';
import PopoverExpandable from '../../high_order/popover_expandable.jsx';

const UpdateSalesforceCredentials = createReactClass({
  propTypes: {
    open: PropTypes.func,
    is_open: PropTypes.bool
  },

  getKey() {
    return 'update_salesforce_credentials_button';
  },

  render() {
    const form = <SalesforceCredentialsForm handlePopoverClose={this.props.open} />;
    return (
      <div className="pop__container">
        <button className="button dark" onClick={this.props.open}>Update Salesforce Credentials</button>
        <Popover
          is_open={this.props.is_open}
          edit_row={form}
          right
        />
      </div>
    );
  }
});

export default PopoverExpandable(UpdateSalesforceCredentials);
