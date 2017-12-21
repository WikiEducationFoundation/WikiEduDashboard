import React from 'react';
import PropTypes from 'prop-types';
import Popover from '../common/popover.jsx';
import PopoverExpandable from '../high_order/popover_expandable.jsx';
import AddAdminForm from './add_admin_form';

class AddAdminButton extends React.Component {
  constructor() {
    super();
    this.getKey = this.getKey.bind(this);
    this.render = this.render.bind(this);
  }

  getKey() {
    return `add_${this.props.source}_button`;
  }

  render() {
    const form = <AddAdminForm />
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
}

export default PopoverExpandable(AddAdminButton);

