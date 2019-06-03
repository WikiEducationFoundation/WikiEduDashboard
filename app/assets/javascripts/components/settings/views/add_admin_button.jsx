import createReactClass from 'create-react-class';
import PropTypes from 'prop-types';
import React from 'react';
import AddAdminForm from '../containers/add_admin_form_container';
import Popover from '../../common/popover.jsx';
import PopoverExpandable from '../../high_order/popover_expandable.jsx';

const AddAdminButton = createReactClass({
  propTypes: {
    source: PropTypes.string,
    open: PropTypes.func,
    is_open: PropTypes.bool
  },

  getKey() {
    return 'add_admin_button';
  },

  render() {
    const form = <AddAdminForm handlePopoverClose={this.props.open} />;
    return (
      <div className="pop__container">
        <button className="button dark" onClick={this.props.open}>Add Admin</button>
        <Popover
          is_open={this.props.is_open}
          edit_row={form}
          right
        />
      </div>
    );
  }
});

export default PopoverExpandable(AddAdminButton);

