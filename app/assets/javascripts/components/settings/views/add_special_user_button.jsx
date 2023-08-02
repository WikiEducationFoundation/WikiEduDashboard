import React from 'react';
import AddSpecialUserForm from './add_special_user_form';
import Popover from '../../common/popover.jsx';
import useExpandablePopover from '../../../hooks/useExpandablePopover';

const AddSpecialUserButton = () => {
  const getKey = () => {
    return 'add_special_user_button';
  };

  const { isOpen, ref, open } = useExpandablePopover(getKey);

  const form = <AddSpecialUserForm handlePopoverClose={open} />;
  return (
    <div className="pop__container" ref={ref}>
      <button className="button dark" onClick={open}>Add Special User</button>
      <Popover
        is_open={isOpen}
        edit_row={form}
        right
      />
    </div>
  );
};

export default AddSpecialUserButton;

