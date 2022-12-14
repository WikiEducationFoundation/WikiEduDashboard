import React from 'react';
import createReactClass from 'create-react-class';
import PropTypes from 'prop-types';
import Select from 'react-select';
import selectStyles from '../../styles/select';

const MultiSelectField = createReactClass({
  displayName: 'MultiSelectField',
  propTypes: {
    label: PropTypes.string,
    options: PropTypes.array,
    disabled: PropTypes.bool
  },

  getInitialState() {
    return {
      removeSelected: true,
      stayOpen: false,
      value: this.props.selected,
      rtl: false,
    };
  },

  componentDidUpdate(prevProps) {
    if (this.props.selected.length !== prevProps.selected.length) {
      // eslint-disable-next-line react/no-did-update-set-state
      this.setState({
        value: this.props.selected
      });
    }
  },

  handleSelectChange(value) {
    this.setState({ value });
    this.props.setSelectedFilters(value || []);
  },

  render() {
    const { stayOpen, value } = this.state;
    const options = this.props.options;
    return (
      <div className="section">
        <Select
          closeOnSelect={!stayOpen}
          isDisabled={this.props.disabled || false}
          isMulti
          onChange={this.handleSelectChange}
          options={options}
          placeholder={this.props.label}
          removeSelected={this.state.removeSelected}
          rtl={this.state.rtl}
          simpleValue
          value={value}
          styles={selectStyles}
        />
      </div>
    );
  }
});

export default MultiSelectField;
