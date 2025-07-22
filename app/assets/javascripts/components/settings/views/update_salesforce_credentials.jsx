import React from 'react';
import SalesforceCredentialsForm from '../containers/salesforce_credentials_form_container';
import Popover from '../../common/popover.jsx';
import useExpandablePopover from '../../../hooks/useExpandablePopover';

const UpdateSalesforceCredentials = () => {
  const getKey = () => {
    return 'update_salesforce_credentials_button';
  };

  const { isOpen, ref, open } = useExpandablePopover(getKey);

  const form = <SalesforceCredentialsForm handlePopoverClose={open} />;
  return (
    <div className="pop__container" ref={ref}>
      <button className="button dark" onClick={open}>Update Salesforce Credentials</button>
      <Popover
        is_open={isOpen}
        edit_row={form}
        right
      />
    </div>
  );
};

export default UpdateSalesforceCredentials;
