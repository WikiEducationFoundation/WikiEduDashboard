import React from 'react';
import createReactClass from 'create-react-class';
import Select from 'react-select';
import { connect } from "react-redux";

import PopoverExpandable from '../high_order/popover_expandable.jsx';

const getState = () =>
  ({
    selectedOption: ''
  })
;
const CampaignButton = createReactClass({

  getInitialState() {
    return getState();
  },

  handleChange(selectedOption) {
    this.setState({ selectedOption });
  },
  render() {
    const value = this.state.selectedOption && this.state.selectedOption.value;

    return (
      <Select
        name="form-field-name"
        value={value}
        onChange={this.handleChange}
        options={[
          { value: 'one', label: 'One' },
          { value: 'two', label: 'Two' },
        ]}
      />
    );
  }

});

const mapDispatchToProps = { };

export default connect(null, mapDispatchToProps)(
  PopoverExpandable(CampaignButton)
);
