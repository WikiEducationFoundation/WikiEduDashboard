import React from 'react';
import createReactClass from 'create-react-class';
import uuid from 'uuid';
import _ from 'lodash';
import shallowCompare from 'react-addons-shallow-compare';
import ValidationStore from '../../stores/validation_store.js';
import ValidationActions from '../../actions/validation_actions.js';

// This needs to be implemented as a mixin for state reasons.
// If there's a good way for high-order components to set state on
// children like this then let's use it.

const InputHOC = (Component) => {
  return createReactClass({
    displayName: `Input${Component.displayName}`,

    mixins: [ValidationStore.mixin],
    // value passed is HOC's state value
    getInitialState() {
      return { value: this.props.value };
    },

    componentWillReceiveProps(props) {
      return this.setState(
        {
          value: props.value,
          id: props.id || this.state.id || uuid.v4() // create a UUID if no id prop
        }, function () {
          const valid = ValidationStore.getValidation(this.props.value_key);
          if (valid && this.props.required && (!props.value || props.value === null || props.value.length === 0)) {
            return ValidationActions.initialize(this.props.value_key, I18n.t('application.field_required'));
          }
        }
      );
    },

    shouldComponentUpdate(nextProps, nextState) {
      return shallowCompare(this, nextProps, nextState);
    },
    // onChange will now be handled by the HOC component
    onChange(e) {
      let value;
      // Workaround to ensure that we don't render checkboxes with a string value instead of boolean
      if (Component.displayName === 'Checkbox') {
        value = /true/.test(e.target.value);
      } else {
        value = e.target.value;
      }

      if (value !== this.state.value) {
        return this.setState({ value }, function () {
          this.props.onChange(this.props.value_key, value);
          return this.validate();
        });
      }
    },

    storeDidChange() {
      return this.setState({ invalid: !ValidationStore.getValidation(this.props.value_key) });
    },

    validate() {
      if (this.props.required || this.props.validation) {
        const filled = (this.state.value && this.state.value.length > 0);
        let charcheck;
        if (this.props.validation instanceof RegExp) {
          charcheck = (new RegExp(this.props.validation)).test(this.state.value);
        } else if (typeof (this.props.validation) === 'function') {
          charcheck = this.props.validation(this.state.value);
        }
        if (this.props.required && !filled) {
          if (_.has(this.props, 'disableSave')) {
            this.props.disableSave(true);
          }
          return ValidationActions.setInvalid(this.props.value_key, I18n.t('application.field_required'));
        } else if (this.props.validation && !charcheck) {
          const invalidMessage = this.props.invalidMessage || I18n.t('application.field_invalid_characters');
          return ValidationActions.setInvalid(this.props.value_key, invalidMessage);
        }
        return ValidationActions.setValid(this.props.value_key);
      }
    },

    focus() {
      if (this.props.onFocus) { return this.props.onFocus(); }
    },

    blur() {
      if (this.props.onBlur) { return this.props.onBlur(); }
    },

    render() {
      // Don't allow uneccessary props to pass through
      const { value, validation, onChange, invalidMessage, required, ...passThroughProps } = this.props;
      return (<Component {...passThroughProps} {...this.state} onChange={this.onChange} onFocus={this.focus} onBlur={this.blur} />);
    }
  });
};

export default InputHOC;
