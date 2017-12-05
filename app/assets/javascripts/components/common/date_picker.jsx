import React from 'react';
import createReactClass from 'create-react-class';
import PropTypes from 'prop-types';
import DayPicker from 'react-day-picker';
import OnClickOutside from 'react-onclickoutside';
import _ from 'lodash';

import InputMixin from '../../mixins/input_mixin.js';
import Conditional from '../high_order/conditional.jsx';
import CourseDateUtils from '../../utils/course_date_utils.js';

const DatePicker = createReactClass({
  displayName: 'DatePicker',

  propTypes: {
    id: PropTypes.string,
    value: PropTypes.string,
    value_key: PropTypes.string,
    spacer: PropTypes.string,
    label: PropTypes.string,
    timeLabel: PropTypes.string,
    valueClass: PropTypes.string,
    editable: PropTypes.bool,
    enabled: PropTypes.bool,
    focus: PropTypes.bool,
    inline: PropTypes.bool,
    isClearable: PropTypes.bool,
    placeholder: PropTypes.string,
    p_tag_classname: PropTypes.string,
    onBlur: PropTypes.func,
    onFocus: PropTypes.func,
    onChange: PropTypes.func,
    onClick: PropTypes.func,
    append: PropTypes.string,
    date_props: PropTypes.object,
    showTime: PropTypes.bool
  },

  mixins: [InputMixin],

  getDefaultProps() {
    return {
      invalidMessage: I18n.t('application.field_invalid_date')
    };
  },

  getInitialState() {
    if (this.props.value) {
      const dateObj = this.moment(this.props.value);
      return {
        value: dateObj.format('YYYY-MM-DD'),
        hour: dateObj.hour(),
        minute: dateObj.minute(),
        datePickerVisible: false
      };
    }
    return {
      value: '',
      hour: 0,
      minute: 0,
      datePickerVisible: false
    };
  },

  componentWillReceiveProps(nextProps) {
    const dateObj = this.moment(nextProps.value);
    if (dateObj.isValid()) {
      this.setState({
        value: dateObj.format('YYYY-MM-DD'),
        hour: dateObj.hour(),
        minute: dateObj.minute()
      });
    }
  },

  /**
   * Update parent component with new date value.
   * Used instead of onChange() in InputMixin because we need to
   *   call this.props.onChange with the full date string, not just YYYY-MM-DD
   * @return {null}
   */
  onChangeHandler() {
    this.props.onChange(this.props.value_key, this.getDate().format());
  },

  /**
   * Get moment object of currently select date, hour and minute
   * @return {moment}
   */
  getDate() {
    let dateObj = this.moment(this.state.value, 'YYYY-MM-DD');
    dateObj = dateObj.hour(this.state.hour);
    return dateObj.minute(this.state.minute);
  },

  getFormattedDate() {
    return this.getDate().format('YYYY-MM-DD');
  },

  /**
   * Get formatted date to be displayed as text,
   *   based on whether or not to include the time
   * @return {String} formatted date
   */
  getFormattedDateTime() {
    return CourseDateUtils.formattedDateTime(this.getDate(), this.props.showTime);
  },

  getTimeDropdownOptions(type) {
    return _.range(0, type === 'hour' ? 24 : 60).map(value => {
      return (
        <option value={value} key={`timedropdown-${type}-${value}`}>
          {(`00${value}`).slice(-2)}
        </option>
      );
    });
  },

  handleDatePickerChange(e, selectedDate) {
    const date = this.moment(selectedDate);
    if (this.isDayDisabled(date)) {
      return;
    }
    this.refs.datefield.focus();
    this.setState({
      value: date.format('YYYY-MM-DD'),
      datePickerVisible: false
    }, this.onChangeHandler);
  },

  /**
   * Update value of date input field.
   * Does not issue callbacks to parent component.
   * @param  {Event} e - input change event
   * @return {null}
   */
  handleDateFieldChange(e) {
    const { value } = e.target;
    if (value !== this.state.value) {
      this.setState({ value });
    }
  },

  /**
   * When they blur out of the date input field,
   * update the state if valid or revert back to last valid value
   * @param  {Event} e - blur event
   * @return {null}
   */
  handleDateFieldBlur(e) {
    const { value } = e.target;
    if (this.isValidDate(value) && !this.isDayDisabled(value)) {
      this.setState({ value }, () => {
        this.onChangeHandler();
        this.validate(); // make sure validations are set as valid
      });
    } else {
      this.setState({ value: this.getInitialState().value });
    }
  },

  handleHourFieldChange(e) {
    this.setState({
      hour: e.target.value
    }, this.onChangeHandler);
  },

  handleMinuteFieldChange(e) {
    this.setState({
      minute: e.target.value
    }, this.onChangeHandler);
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
    const currentDate = this.moment(date).format('YYYY-MM-DD');
    return currentDate === this.state.value;
  },

  isDayDisabled(date) {
    const currentDate = this.moment(date);
    if (this.props.date_props) {
      const minDate = this.moment(this.props.date_props.minDate, 'YYYY-MM-DD').startOf('day');
      if (minDate.isValid() && currentDate < minDate) {
        return true;
      }

      const maxDate = this.moment(this.props.date_props.maxDate, 'YYYY-MM-DD').endOf('day');
      if (maxDate.isValid() && currentDate > maxDate) {
        return true;
      }
    }
  },

  /**
   * Validates given date string (should be similar to YYYY-MM-DD).
   * This is implemented here to be self-contained within DatePicker.
   * @param  {String} value - date string
   * @return {Boolean} valid or not
   */
  isValidDate(value) {
    const validationRegex = /^20\d\d-(0?[1-9]|1[012])-(0?[1-9]|[12][0-9]|3[01])/;
    return validationRegex.test(value) && moment(value, 'YYYY-MM-DD').isValid();
  },

  moment(...args) {
    return this.props.showTime ? moment(...args) : moment(...args).utc();
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
        const minDateValue = this.moment(this.props.date_props.minDate, 'YYYY-MM-DD');
        if (minDateValue.isValid()) {
          minDate = minDateValue;
        }
      }

      // don't validate YYYY-MM-DD format so we can update the daypicker as they type
      const date = moment(this.state.value, 'YYYY-MM-DD');
      if (date.isValid()) {
        currentMonth = this.moment(date).toDate();
      } else if (minDate) {
        currentMonth = this.moment(minDate).toDate();
      } else {
        currentMonth = this.moment().toDate();
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
            value={this.state.value || ''}
            className={`${inputClass} ${this.props.value_key}`}
            onChange={this.handleDateFieldChange}
            onClick={this.handleDateFieldClick}
            disabled={this.props.enabled && !this.props.enabled}
            autoFocus={this.props.focus}
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
              className={`time-input__hour ${inputClass}`}
              onChange={this.handleHourFieldChange}
              value={this.state.hour}
            >
              {this.getTimeDropdownOptions('hour')}
            </select>
            :
            <select
              className={`time-input__minute ${inputClass}`}
              onChange={this.handleMinuteFieldChange}
              value={this.state.minute}
            >
              {this.getTimeDropdownOptions('minute')}
            </select>
          </div>
        </span>
      );

      return (
        <div className={`form-group datetime-control ${this.props.id}-datetime-control ${inputClass}`}>
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
      <span>{this.getFormattedDateTime()}</span>
    );
  }
});

export default Conditional(OnClickOutside(DatePicker));
