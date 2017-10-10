import React from 'react';
import createReactClass from 'create-react-class';
import PropTypes from 'prop-types';
import LookupWrapper from '../high_order/lookup_wrapper.jsx';

const LookupSelect = createReactClass({
  displayName: 'LookupSelect',

  propTypes: {
    placeholder: PropTypes.string,
    models: PropTypes.array
  },
  getValue() {
    return this.refs.entry.value;
  },
  clear() {
    return this.refs.entry.value = 'placeholder';
  },
  render() {
    const placeholder = `Select a ${this.props.placeholder}` || 'Select one';
    const options = this.props.models.map((model) => {
      return <option value={model} key={model}>{model}</option>;
    });

    return (
      <select name={this.props.placeholder.toLowerCase()} ref="entry" defaultValue="placeholder">
        <option
          value="placeholder"
          key="placeholder"
          disabled={true}
        >
          {placeholder}
        </option>
        {options}
      </select>
    );
  }
}
);

export default LookupWrapper(LookupSelect);
