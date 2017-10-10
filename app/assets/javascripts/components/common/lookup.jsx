import React from 'react';
import createReactClass from 'create-react-class';
import PropTypes from 'prop-types';
import { Typeahead } from 'react-typeahead';
import LookupWrapper from '../high_order/lookup_wrapper.jsx';

const Lookup = createReactClass({
  displayName: 'Lookup',

  propTypes: {
    disabled: PropTypes.bool,
    onSubmit: PropTypes.func,
    onChange: PropTypes.func,
    value: PropTypes.string,
    placeholder: PropTypes.string,
    models: PropTypes.array
  },

  getValue() {
    if (!this.props.disabled) {
      return this.refs.entry.state.entryValue;
    }
    return this.refs.entry.getDOMNode().value;
  },

  clear() {
    if (!this.props.disabled) {
      return this.refs.entry.setState({ entryValue: '' });
    }
    return this.refs.entry.getDOMNode().value = '';
  },

  optionSelectedHandler(option, e) {
    return this.keyDownHandler(e);
  },

  keyDownHandler(e) {
    const madeSelection = (this.refs.entry.getSelection() !== null);
    const selectionMatches = this.refs.entry.getSelection() === this.getValue();
    if (e.keyCode === 13 && this.getValue() !== '' && (selectionMatches || !madeSelection)) {
      return this.props.onSubmit(e);
    }
  },

  render() {
    const placeholder = this.props.placeholder || I18n.t('courses.start_typing');
    if (!this.props.disabled) {
      return (
        <Typeahead
          options={this.props.models}
          placeholder={placeholder}
          maxVisible={5}
          ref="entry"
          onKeyDown={this.keyDownHandler}
          onOptionSelected={this.optionSelectedHandler}
        />
      );
    }
    return (
      <input
        value={this.props.value}
        onChange={this.props.onChange}
        placeholder={placeholder}
        ref="entry"
      />
    );
  }
});

export default LookupWrapper(Lookup);
