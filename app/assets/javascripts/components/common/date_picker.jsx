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
    timeLabel: React.PropTypes.string,
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
    date_props: React.PropTypes.object,
    showTime: React.PropTypes.bool
  },

  mixins: [InputMixin],

  getDefaultProps() {
    return {
      invalidMessage: I18n.t('application.field_invalid_date')
    };
  },

  getInitialState() {
    return {
      value: moment(this.props.value).utc(),
      datePickerVisible: false
    };
  },

  componentWillReceiveProps(nextProps) {
    if (this.state.value === null) {
      this.setState({ value: moment(nextProps.value).utc() });
    }
  },

  getDate() {
    return moment(this.state.value).utc();
  },

  getFormattedDate() {
    return this.getDate().format('YYYY-MM-DD');
  },

  getFormattedDateTime() {
    const format = `YYYY-MM-DD${this.props.showTime ? ' HH:mm (UTC)' : ''}`;
    return this.getDate().format(format);
  },

  getTimeDropdownOptions(type) {
    return _.range(0, type === 'hour' ? 24 : 60).map(value => {
      return (
        <option value={value} key={`timedropdown-${type}-${value}`}>
          {value}
        </option>
      );
    });
  },

  handleDatePickerChange(e, selectedDate, modifiers) {
    if (_.includes(modifiers, 'disabled')) {
      return;
    }
    const date = moment(selectedDate).utc().format('YYYY-MM-DD');
    this.onChange({ target: { value: date } });
    this.refs.datefield.focus();
    this.setState({ datePickerVisible: false });
  },

  handleDateFieldChange(e) {
    const { value } = e.target;
    this.onChange({ target: { value } });
  },

  handleHourFieldChange(e) {
    const { value } = e.target;
    this.onChange({ target: { value } });
  },

  handleMinuteFieldChange(e) {
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
    const currentDate = moment(date).utc().format('YYYY-MM-DD');
    return currentDate === moment(this.state.value).utc().format('YYYY-MM-DD');
  },

  isDayDisabled(date) {
    const currentDate = moment(date).utc();
    if (this.props.date_props) {
      const minDate = moment(this.props.date_props.minDate, 'YYYY-MM-DD').utc().startOf('day');
      if (minDate.isValid() && currentDate < minDate) {
        return true;
      }

      const maxDate = moment(this.props.date_props.maxDate, 'YYYY-MM-DD').utc().endOf('day');
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
    let timeLabel;
    let currentMonth;

    if (this.props.label) {
      label = this.props.label;
      label += spacer;
    }

    if (this.props.timeLabel) {
      timeLabel = this.props.timeLabel;
      timeLabel += spacer;
    } else {
      // use unicode for &nbsp; to account for spacing when there is no label
      timeLabel = '\u00A0';
    }

    const value = moment(this.props.value).utc();

    let valueClass = 'text-input-component__value ';
    if (this.props.valueClass) { valueClass += this.props.valueClass; }

    if (this.props.editable) {
      let labelClass = '';
      let inputClass = (this.props.inline !== null) && this.props.inline ? ' inline' : '';

      if (this.state.invalid) {
        labelClass += 'red';
        inputClass += 'invalid';
      }

      let minDate;
      if (this.props.date_props && this.props.date_props.minDate) {
        const minDateValue = moment(this.props.date_props.minDate, 'YYYY-MM-DD').utc();
        if (minDateValue.isValid()) {
          minDate = minDateValue;
        }
      }

      if (value.isValid()) {
        currentMonth = value.toDate();
      } else if (minDate) {
        currentMonth = minDate.toDate();
      } else {
        currentMonth = new Date();
      }

      const modifiers = {
        selected: this.isDaySelected,
        disabled: this.isDayDisabled
      };

      const dateInput = (
        <div className="date-input">
          <input
            id={this.state.id}
            ref="datefield"
            value={this.getFormattedDate()}
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

      const timeControlNode = (
        <span className={`form-group time-picker--form-group ${inputClass}`}>
          <label htmlFor={`${this.state.id}-hour`} className={labelClass}>
            {timeLabel}
          </label>
          <div className="time-input">
            <select
              className="time-input__hour"
              onChange={this.handleHourFieldChange}
              value={value.utc().hour()}
            >
              {this.getTimeDropdownOptions('hour')}
            </select>
            :
            <select
              className="time-input__minute"
              onChange={this.handleMinuteFieldChange}
              value={value.utc().minute()}
            >
              {this.getTimeDropdownOptions('minute')}
            </select>
          </div>
        </span>
      );

      return (
        <div className={`form-group datetime-control ${inputClass}`}>
          <span className={`form-group date-picker--form-group ${inputClass}`}>
            <label htmlFor={this.state.id}className={labelClass}>{label}</label>
            {dateInput}
          </span>
          {this.props.showTime ? timeControlNode : null}
        </div>
      );
    } else if (this.props.label !== null) {
      return (
        <p className={this.props.p_tag_classname}>
          <span className="text-input-component__label"><strong>{label}</strong></span>
          <span>{(this.props.value !== null || this.props.editable) && !this.props.label ? spacer : null}</span>
          <span onBlur={this.props.onBlur} onClick={this.props.onClick} className={valueClass}>
            {this.getFormattedDateTime()}
          </span>
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
