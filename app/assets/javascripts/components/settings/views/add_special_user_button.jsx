import createReactClass from 'create-react-class';
import PropTypes from 'prop-types';
import React from 'react';
import AddSpecialUserForm from './add_special_user_form';
import Popover from '../../common/popover.jsx';
import PopoverExpandable from '../../high_order/popover_expandable.jsx';

const AddSpecialUserButton = createReactClass({
  propTypes: {
    source: PropTypes.string,
    opne: PropTypes.func,
    is_open: PropTypes.bool
  },

  getKey() {
    return 'add_special_user_button';
  },

  render() {
    const form = <AddSpecialUserForm handlePopoverClose={this.props.open} />;
    return (
      <div className="pop__container">
        <button className="button dark" onClick={this.props.open}>Add Special User</button>
        <Popover
          is_open={this.props.is_open}
          edit_row={form}
          right
        />
      </div>
    );
  }
});

export default PopoverExpandable(AddSpecialUserButton);

