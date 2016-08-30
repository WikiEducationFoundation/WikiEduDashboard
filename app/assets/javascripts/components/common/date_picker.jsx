import React from 'react';
import DayPicker from 'react-day-picker';
import OnClickOutside from 'react-onclickoutside';
import InputMixin from '../../mixins/input_mixin.js';
import Conditional from '../high_order/conditional.jsx';

const DatePicker = React.createClass({
  displayName: 'DatePicker',

  propTypes: {
    id: React.PropTypes.string,
    value: React.PropTypes.string,
    value_key: React.PropTypes.string,
    spacer: React.PropTypes.string,
    label: React.PropTypes.string,
    valueClass: React.PropTypes.string,
    editable: React.PropTypes.bool,
    enabled: React.PropTypes.bool,
    focus: React.PropTypes.bool,
    inline: React.PropTypes.bool,
    isClearable: React.PropTypes.bool,
    placeholder: React.PropTypes.string,
    p_tag_classname: React.PropTypes.string,
    onBlur: React.PropTypes.func,
    onFocus: React.PropTypes.func,
    onClick: React.PropTypes.func,
    append: React.PropTypes.string,
    date_props: React.PropTypes.object
  },

  mixins: [InputMixin],

  getDefaultProps() {
    return {
      invalidMessage: I18n.t('application.field_invalid_date')
    };
  },

  getInitialState() {
    return {
      value: this.props.value,
      datePickerVisible: false
    };
  },

  componentWillReceiveProps(nextProps) {
    if (this.state.value === null) {
      this.setState({ value: nextProps.value });
    }
  },

  handleDatePickerChange(e, selectedDate, modifiers) {
    if (_.includes(modifiers, 'disabled')) {
      return;
    }
    const date = moment(selectedDate).format('YYYY-MM-DD');
    this.onChange({ target: { value: date } });
    this.refs.datefield.focus();
    this.setState({ datePickerVisible: false });
  },

  handleDateFieldChange(e) {
    const { value } = e.target;
    this.onChange({ target: { value } });
  },

  handleClickOutside() {
    if (this.state.datePickerVisible) {
      this.setState({ datePickerVisible: false });
    }
  },

  handleDateFieldClick() {
    if (!this.state.datePickerVisible) {
      this.setState({ datePickerVisible: true });
    }
  },

  handleDateFieldFocus() {
    this.setState({ datePickerVisible: true });
  },

  handleDateFieldKeyDown(e) {
    // Close picker if tab, enter, or escape
    if (_.includes([9, 13, 27], e.keyCode)) {
      this.setState({ datePickerVisible: false });
    }
  },

  isDaySelected(date) {
    const currentDate = moment(date).format('YYYY-MM-DD');
    return currentDate === this.state.value;
  },

  isDayDisabled(date) {
    const currentDate = moment(date);
    if (this.props.date_props) {
      const minDate = moment(this.props.date_props.minDate, 'YYYY-MM-DD').startOf('day');
      if (minDate.isValid() && currentDate < minDate) {
        return true;
      }

      const maxDate = moment(this.props.date_props.maxDate, 'YYYY-MM-DD').endOf('day');
      if (maxDate.isValid() && currentDate > maxDate) {
        return true;
      }
    }
  },

  showCurrentDate() {
    return this.refs.daypicker.showMonth(this.state.month);
  },

  render() {
    const spacer = this.props.spacer || ': ';
    let label;
    let currentMonth;

    if (this.props.label) {
      label = this.props.label;
      label += spacer;
    }

    const { value } = this.props;

    let valueClass = 'text-input-component__value ';
    if (this.props.valueClass) { valueClass += this.props.valueClass; }

    if (this.props.editable) {
      let labelClass = '';
      let inputClass = (this.props.inline !== null) && this.props.inline ? ' inline' : '';

      if (this.state.invalid) {
        labelClass += 'red';
        inputClass += 'invalid';
      }

      const date = moment(this.state.value, 'YYYY-MM-DD');

      if (this.props.date_props && this.props.date_props.minDate) {
        currentMonth = this.props.date_props.minDate.toDate();
      } else if (date.isValid()) {
        currentMonth = date.toDate();
      } else {
        currentMonth = new Date();
      }

      const modifiers = {
        selected: this.isDaySelected,
        disabled: this.isDayDisabled
      };

      const input = (
        <div className="date-input">
          <input
            id={this.state.id}
            ref="datefield"
            value={this.state.value}
            className={`${inputClass} ${this.props.value_key}`}
            onChange={this.handleDateFieldChange}
            onClick={this.handleDateFieldClick}
            disabled={this.props.enabled && !this.props.enabled}
            autoFocus={this.props.focus}
            isClearable={this.props.isClearable}
            onFocus={this.handleDateFieldFocus}
            onBlur={this.handleDateFieldBlur}
            onKeyDown={this.handleDateFieldKeyDown}
            placeholder={this.props.placeholder}
          />

          <DayPicker
            className={this.state.datePickerVisible ? 'DayPicker--visible ignore-react-onclickoutside' : null}
            ref="daypicker"
            tabIndex={-1}
            modifiers={modifiers}
            disabledDays={this.isDayDisabled}
            onDayClick={this.handleDatePickerChange}
            initialMonth={currentMonth}
          />
        </div>
      );

      return (
        <div className={`form-group ${inputClass}`}>
          <label htmlFor={this.state.id}className={labelClass}>{label}</label>
          {input}
        </div>
      );
    } else if (this.props.label !== null) {
      return (
        <p className={this.props.p_tag_classname}>
          <span className="text-input-component__label"><strong>{label}</strong></span>
          <span>{(this.props.value !== null || this.props.editable) && !this.props.label ? spacer : null}</span>
          <span onBlur={this.props.onBlur} onClick={this.props.onClick} className={valueClass}>{value}</span>
          {this.props.append}
        </p>
      );
    }

    return (
      <span>{value}</span>
    );
  }
});

export default Conditional(OnClickOutside(DatePicker));
