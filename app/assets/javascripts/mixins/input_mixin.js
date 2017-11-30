import shallowCompare from 'react-addons-shallow-compare';
import ValidationStore from '../stores/validation_store.js';
import ValidationActions from '../actions/validation_actions.js';
import uuid from 'uuid';
import _ from 'lodash';

// This needs to be implemented as a mixin for state reasons.
// If there's a good way for high-order components to set state on
// children like this then let's use it.

const InputMixin = {
  mixins: [ValidationStore.mixin],

  storeDidChange() {
    return this.setState({ invalid: !ValidationStore.getValidation(this.props.value_key) });
  },

  shouldComponentUpdate(nextProps, nextState) {
    return shallowCompare(this, nextProps, nextState);
  },

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
        return ValidationActions.setInvalid(this.props.value_key, I18n.t('application.field_required'));
      } else if (this.props.validation && !charcheck) {
        const invalidMessage = this.props.invalidMessage || I18n.t('application.field_invalid_characters');
        return ValidationActions.setInvalid(this.props.value_key, invalidMessage);
      }
      return ValidationActions.setValid(this.props.value_key);
    }
  },

  componentWillReceiveProps(props) {
    return this.setState(
      {
        value: props.value,
        id: props.id || this.state.id || uuid.v4() // create a UUID if no id prop
      }
      , function () {
        const valid = ValidationStore.getValidation(this.props.value_key);
        if (valid && this.props.required && (!props.value || props.value === null || props.value.length === 0)) {
          return ValidationActions.initialize(this.props.value_key, I18n.t('application.field_required'));
        }
      }
    );
  },

  focus() {
    if (this.props.onFocus) { return this.props.onFocus(); }
  },

  blur() {
    if (this.props.onBlur) { return this.props.onBlur(); }
  }
};

export default InputMixin;
