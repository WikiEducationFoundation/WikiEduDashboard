import React from 'react';
import { connect } from 'react-redux';
import createReactClass from 'create-react-class';
import uuid from 'uuid';
import { has } from 'lodash-es';
import { addValidation, setValid, setInvalid } from '../../actions/validation_actions';

// This needs to be implemented as a mixin for state reasons.
// If there's a good way for high-order components to set state on
// children like this then let's use it.


const getValidation = (key, validations) => {
  if (validations[key] && validations[key].changed) {
    return validations[key].valid;
  }
  return true;
};

const mapStateToProps = state => ({
  validations: state.validations.validations,
  errorQueue: state.validations.errorQueue
});

const mapDispatchToProps = {
  addValidation,
  setValid,
  setInvalid,
};

const InputHOC = (Component) => {
  const validatingComponent = createReactClass({
    displayName: `Input${Component.displayName}`,

    // value passed is HOC's state value
    getInitialState() {
      return { value: this.props.value };
    },

    shouldComponentUpdate(nextProps, nextState) {
      if (this.state.value === nextState.value
            && this.state.id === nextState.id
            && this.state.invalid === nextState.invalid
            && this.props.editable === nextProps.editable
            && this.props.day === nextProps.day
            && nextProps.rerenderHoc !== true
            && this.props._value === nextProps._value) {
        return false;
      }
      return true;
    },
    // onChange will now be handled by the HOC component
    onChange(e, originalEvent) {
      let value;
      // Workaround to ensure that we don't render checkboxes with a string value instead of boolean
      if (Component.displayName === 'Checkbox') {
        value = /true/.test(e.target.value);
      } else {
        value = e.target.value;
      }

      if (value !== this.state.value) {
        return this.setState({ value }, function () {
          this.props.onChange(this.props.value_key, value, originalEvent);
          return this.validate();
        });
      }
    },

    UNSAFE_componentWillReceiveProps(props) {
      const valid = getValidation(props.value_key, props.validations);

      return this.setState(
        {
          value: props.value,
          invalid: !valid,
          day: props.day,
          id: props.id || this.state.id || uuid.v4() // create a UUID if no id prop
        }, function () {
          if (valid && this.props.required && (!props.value || props.value === null || props.value.length === 0)) {
            return this.props.addValidation(this.props.value_key, I18n.t('application.field_required'));
          }
        }
      );
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
          if (has(this.props, 'disableSave')) {
            this.props.disableSave(true);
          }
          return this.props.setInvalid(this.props.value_key, I18n.t('application.field_required'));
        } else if (this.props.validation && !charcheck) {
          const invalidMessage = this.props.invalidMessage || I18n.t('application.field_invalid_characters');
          return this.props.setInvalid(this.props.value_key, invalidMessage);
        }
        return this.props.setValid(this.props.value_key);
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
      const { value, validation, day, onChange, invalidMessage, required, ...passThroughProps } = this.props;
      return (<Component {...passThroughProps} {...this.day} {...this.state} onChange={this.onChange} onFocus={this.focus} onBlur={this.blur} />);
    }
  });
  return connect(mapStateToProps, mapDispatchToProps)(validatingComponent);
};

export default InputHOC;
