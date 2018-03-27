import React from 'react';
import createClass from 'create-react-class';
import PropTypes from 'prop-types';
import Select from 'react-select';

const MultiSelectField = createClass({
  displayName: 'MultiSelectField',
  propTypes: {
    label: PropTypes.string,
    options: PropTypes.array,
  },

  getInitialState() {
    return {
      removeSelected: true,
      disabled: false,
      stayOpen: false,
      value: this.props.selected,
      rtl: false,
    };
  },

  handleSelectChange(value) {
    this.setState({ value });
    this.props.setSelectedFilters(value);
  },

  render() {
    const { disabled, stayOpen, value } = this.state;
    const options = this.props.options;
    return (
      <div className="section">
        <Select
          closeOnSelect={!stayOpen}
          disabled={disabled}
          multi
          onChange={this.handleSelectChange}
          options={options}
          placeholder="Select"
          removeSelected={this.state.removeSelected}
          rtl={this.state.rtl}
          simpleValue
          value={value}
        />
      </div>
    );
  }
});

module.exports = MultiSelectField;
