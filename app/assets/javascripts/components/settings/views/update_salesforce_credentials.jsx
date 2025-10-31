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
      <button type="button" className="button dark" onClick={open}>{I18n.t('settings.common_settings_components.buttons.update_salesforce_credentials')}</button>
      <Popover
        is_open={isOpen}
        edit_row={form}
        right
      />
    </div>
  );
};

export default UpdateSalesforceCredentials;
