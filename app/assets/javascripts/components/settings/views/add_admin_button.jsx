import React from 'react';
import AddAdminForm from '../containers/add_admin_form_container';
import Popover from '../../common/popover.jsx';
import useExpandablePopover from '../../../hooks/useExpandablePopover';

const AddAdminButton = () => {
  const getKey = () => {
    return 'add_admin_button';
  };

  const { isOpen, ref, open } = useExpandablePopover(getKey);

  const form = <AddAdminForm handlePopoverClose={open} />;
  return (
    <div className="pop__container" ref={ref}>
      <button className="button dark" onClick={open}>{I18n.t('settings.common_settings_components.buttons.add_admin_button')}</button>
      <Popover
        is_open={isOpen}
        edit_row={form}
        right
      />
    </div>
  );
};

export default AddAdminButton;

