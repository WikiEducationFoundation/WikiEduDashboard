import React from 'react';
import Popover from '../../common/popover.jsx';
import useExpandablePopover from '../../../hooks/useExpandablePopover';
import AddDisallowedUserForm from './add_disallowed_user_form.jsx';

const AddDisallowedUserButton = () => {
    const getKey = () => {
        return 'add_disallowed_user_button';
    };

    const { isOpen, ref, open } = useExpandablePopover(getKey);

    const form = <AddDisallowedUserForm handlePopoverClose={open} />;
    return (
      <div className="pop__container" ref={ref}>
        <button className="button dark" onClick={open}>
          {I18n.t('settings.disallowed_users.add_button')}
        </button>
        <Popover
          is_open={isOpen}
          edit_row={form}
          right
        />
      </div>
    );
};

export default AddDisallowedUserButton;
