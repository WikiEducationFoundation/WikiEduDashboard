import React from 'react';
import createReactClass from 'create-react-class';
import uuid from 'uuid';
import _ from 'lodash';
import { connect } from 'react-redux';
import shallowCompare from 'react-addons-shallow-compare';
import { initialize, setValid, setInvalid } from '../../actions/validation_actions.js';
import { getValidation } from '../../utils/validation_utils.js';


const mapStateToProps = state => ({
  validations: state.validation.validations,
  errorQueue: state.validation.errorQueue
});

const mapDispatchToProps = {
  initialize,
  setValid,
  setInvalid,
};

const InputHOC = (Component) => {
  const inputComponent = createReactClass({
    displayName: `Input${Component.displayName}`,

    // value passed is HOC's state value
    getInitialState() {
      return { value: this.props.value };
    },

    componentWillReceiveProps(props) {
      if ((props.validations !== this.props.validations) || (props.errorQueue !== this.props.errorQueue)) {
        return this.setState({ invalid: !getValidation(this.props.value_key, this.props.validations) });
      }
      return this.setState(
        {
          value: props.value,
          id: props.id || this.state.id || uuid.v4() // create a UUID if no id prop
        }
        , function () {
          const valid = getValidation(this.props.value_key, this.props.validations);
          if (valid && this.props.required && (!props.value || props.value === null || props.value.length === 0)) {
            return this.props.initialize(this.props.value_key, I18n.t('application.field_required'));
          }
        }
      );
    },

    shouldComponentUpdate(nextProps, nextState) {
      return shallowCompare(this, nextProps, nextState);
    },
    // onChange will now be handled by the HOC component
    onChange(e) {
      const { value } = e.target;
      if (value !== this.state.value) {
        return this.setState({ value }, function () {
          this.props.onChange(this.props.value_key, value);
          return this.validate();
        });
      }
    },

    validate() {
      if (this.props.required || this.props.validation) {
        const filled = (this.state.value && this.state.value.length > 0);
        let charcheck;
        if (this.props.validation instanceof RegExp) {
          charcheck = (new RegExp(this.props.validation)).test(this.state.value);
        } else if (typeof(this.props.validation) === 'function') {
          charcheck = this.props.validation(this.state.value);
        }
        if (this.props.required && !filled) {
          if (_.has(this.props, 'disableSave')) {
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
      const { value, validation, onChange, invalidMessage, required, ...passThroughProps } = this.props;
      return (<Component {...passThroughProps} {...this.state} onChange={this.onChange} onFocus={this.focus} onBlur={this.blur} />);
    }
  });

  return connect(mapStateToProps, mapDispatchToProps)(inputComponent);
};

export default InputHOC;
