import React from 'react';
import OnClickOutside from 'react-onclickoutside';
import InputMixin from '../../mixins/input_mixin.cjsx';
import Conditional from '../high_order/conditional.cjsx';

const DatePicker = React.createClass({
  displayName: 'DatePicker',

  propTypes: {
    value: React.PropTypes.string,
    spacer: React.PropTypes.string,
    label: React.PropTypes.string,
    valueClass: React.PropTypes.string,
    editable: React.PropTypes.boolean,
    inline: React.PropTypes.boolean
  },

  mixins: [InputMixin],

  getInitialState() {
    return {
      value: this.props.value,
      datePickerVisible: false
    };
  },

  componentWillReceiveProps(nextProps) {
    if (this.state.value === null) {
      return this.setState({ value: nextProps.value });
    }
  },

  handleDatePickerChange(e, selectedDate) {
    const date = moment(selectedDate).format('YYYY-MM-DD');
    this.onChange({ target: { value: date } });
    return this.setState({ datePickerVisible: false });
  },

  handleDateFieldChange(e) {
    const { value } = e.target;
    return this.onChange({ target: { value } });
  },

  handleClickOutside() {
    if (this.state.datePickerVisible) {
      return this.setState(
                           { datePickerVisible: false });
    }
  },

  handleDateFieldClick() {
    if (!this.state.datePickerVisible) {
      return this.setState(
                           { datePickerVisible: true });
    }
  },

  handleDateFieldFocus() {
    return this.setState(
                         { datePickerVisible: true });
  },

  handleDateFieldBlur() {
    if (this.state.datePickerVisible) {
      return this.refs.datefield.focus();
    }
  },

  handleDateFieldKeyDown(e) {
    // Close picker if tab, enter, or escape
    if (_.includes([9, 13, 27], e.keyCode)) {
      return this.setState(
                           { datePickerVisible: false });
    }
  },

  isDaySelected(date) {
    const currentDate = moment(date).format('YYYY-MM-DD');
    return currentDate === this.state.value;
  },

  showCurrentDate() {
    return this.refs.daypicker.showMonth(this.state.month);
  },

  render() {
    const spacer = this.props.spacer || ': ';

    if (this.props.label) {
      let { label } = this.props;
      label += spacer;
    }

    const { value } = this.props;

    let valueClass = 'text-input-component__value ';
    if (this.props.valueClass) { valueClass += this.props.valueClass; }

    if (this.props.editable) {
      let modifiers;
      let labelClass = '';
      let inputClass = (this.props.inline !== null) && this.props.inline ? ' inline' : '';

      if (this.state.invalid) {
        labelClass += 'red';
        inputClass += 'invalid';
      }

      const date = moment(this.state.value, 'YYYY-MM-DD');

      if (date.isValid()) {
        const currentMonth = date.toDate();
      } else {
        const currentMonth = new Date();
      }

      return modifiers = { selected: this.isDaySelected };
    }

    
    
  }
});

export default Conditional(OnClickOutside(DatePicker));
