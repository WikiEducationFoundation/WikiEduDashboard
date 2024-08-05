import React, { useState, useRef, useEffect } from 'react';
import PropTypes from 'prop-types';
import DayPicker from 'react-day-picker';
import { useOnClickOutside } from 'react-onclickoutside';
import { range, includes } from 'lodash-es';
import { startOfDay, endOfDay, isValid, isAfter, parseISO, getHours, getMinutes, setHours, setMinutes, formatISO } from 'date-fns';
import InputHOC from '../high_order/input_hoc.jsx';
import Conditional from '../high_order/conditional.jsx';
import CourseDateUtils from '../../utils/course_date_utils.js';
import { formatDateWithoutTime, toDate } from '../../utils/date_utils.js';

const DatePicker = (props) => {
  const {
    id,
    value,
    value_key,
    spacer = ': ',
    label,
    timeLabel,
    valueClass,
    editable,
    enabled,
    focus,
    inline,
    isClearable,
    placeholder,
    p_tag_classname,
    onBlur,
    onFocus,
    onChange,
    onClick,
    append,
    date_props,
    showTime,
    invalidMessage = I18n.t('application.field_invalid_date')
  } = props;

  const getInitialState = () => {
    if (value) {
      const dateObj = toDate(value);
      return {
        value: formatDateWithoutTime(dateObj),
        hour: getHours(dateObj),
        minute: getMinutes(dateObj),
      };
    }
    return {
      value: '',
      hour: 0,
      minute: 0,
    };
  };

  const [state, setState] = useState(getInitialState());
  const [datePickerVisible, setDatePickerVisible] = useState(false);

  const dateFieldRef = useRef(null);
  const dayPickerRef = useRef(null);

  useOnClickOutside(dateFieldRef, () => {
    if (datePickerVisible) {
      setDatePickerVisible(false);
    }
  });

  const getDate = () => {
    let dateObj = toDate(state.value);
    dateObj = setHours(dateObj, state.hour);
    return setMinutes(dateObj, state.minute);
  };

  const getFormattedDate = () => formatDateWithoutTime(getDate());

  const getFormattedDateTime = () => CourseDateUtils.formattedDateTime(getDate(), showTime);

  const onChangeHandler = () => {
    const e = { target: { value: formatISO(getDate()) } };
    onChange(e);
  };

  const handleDatePickerChange = (selectedDate) => {
    const date = toDate(selectedDate);
    if (isDayDisabled(date)) {
      return;
    }
    dateFieldRef.current.focus();
    setState(prevState => ({
      ...prevState,
      value: formatDateWithoutTime(date),
    }));
    setDatePickerVisible(false);
    onChangeHandler();
  };

  const handleDateFieldChange = (e) => {
    const { value } = e.target;
    if (value !== state.value) {
      setState(prevState => ({ ...prevState, value }));
    }
  };

  const handleDateFieldBlur = (e) => {
    const { value } = e.target;
    if (isValidDate(value) && !isDayDisabled(parseISO(value))) {
      setState(prevState => ({ ...prevState, value }));
      onChangeHandler();
    } else {
      setState(getInitialState());
    }
  };

  const handleHourFieldChange = (e) => {
    if (state.value === '') {
      handleDatePickerChange(new Date());
    }
    setState(prevState => ({ ...prevState, hour: e.target.value }));
    onChangeHandler();
  };

  const handleMinuteFieldChange = (e) => {
    if (state.value === '') {
      handleDatePickerChange(new Date());
    }
    setState(prevState => ({ ...prevState, minute: e.target.value }));
    onChangeHandler();
  };

  const handleDateFieldClick = () => {
    if (!datePickerVisible) {
      setDatePickerVisible(true);
    }
  };

  const handleDateFieldFocus = () => {
    setDatePickerVisible(true);
  };

  const handleDateFieldKeyDown = (e) => {
    if (includes([9, 13, 27], e.keyCode)) {
      setDatePickerVisible(false);
    }
  };

  const isDaySelected = (date) => {
    const currentDate = formatDateWithoutTime(date);
    return currentDate === state.value;
  };

  const isDayDisabled = (currentDate) => {
    if (date_props) {
      const minDate = startOfDay(date_props.minDate);
      if (isValid(minDate) && isAfter(minDate, currentDate)) {
        return true;
      }

      const maxDate = endOfDay(date_props.maxDate);
      if (isValid(maxDate) && isAfter(currentDate, maxDate)) {
        return true;
      }
    }
    return false;
  };

  const isValidDate = (value) => {
    const validationRegex = /^20\d\d-(0?[1-9]|1[012])-(0?[1-9]|[12][0-9]|3[01])/;
    return validationRegex.test(value) && isValid(toDate(value));
  };

  const showCurrentDate = () => {
    return dayPickerRef.current.showMonth(state.month);
  };

  const getTimeDropdownOptions = (type) => {
    return range(0, type === 'hour' ? 24 : 60).map((value) => (
      <option value={value} key={`timedropdown-${type}-${value}`}>
        {(`00${value}`).slice(-2)}
      </option>
    ));
  };

  if (editable) {
    let labelClass = '';
    let inputClass = (inline !== null) && inline ? ' inline' : '';

    if (props.invalid) {
      labelClass += 'red';
      inputClass += 'invalid';
    }

    let minDate;
    if (date_props && date_props.minDate) {
      if (isValid(date_props.minDate)) {
        minDate = date_props.minDate;
      }
    }

    const date = parseISO(state.value);
    const currentMonth = isValid(date) ? date : (minDate || new Date());

    const modifiers = {
      selected: isDaySelected,
      disabled: isDayDisabled
    };

    const dateInput = (
      <div className="date-input">
        <input
          id={id}
          ref={dateFieldRef}
          value={state.value || ''}
          className={`${inputClass} ${value_key}`}
          onChange={handleDateFieldChange}
          onClick={handleDateFieldClick}
          disabled={enabled && !enabled}
          autoFocus={focus}
          onFocus={handleDateFieldFocus}
          onBlur={handleDateFieldBlur}
          onKeyDown={handleDateFieldKeyDown}
          placeholder={placeholder}
        />

        <DayPicker
          className={datePickerVisible ? 'DayPicker--visible ignore-react-onclickoutside' : null}
          ref={dayPickerRef}
          tabIndex={-1}
          modifiers={modifiers}
          disabledDays={isDayDisabled}
          onDayClick={handleDatePickerChange}
          month={currentMonth}
        />
      </div>
    );

    const timeControlNode = showTime && (
      <span className={`form-group time-picker--form-group ${inputClass}`}>
        <label htmlFor={`${id}-hour`} className={labelClass}>
          {timeLabel || '\u00A0'}
        </label>
        <div className="time-input">
          <select
            className={`time-input__hour ${inputClass}`}
            onChange={handleHourFieldChange}
            value={state.hour}
          >
            {getTimeDropdownOptions('hour')}
          </select>
          :
          <select
            className={`time-input__minute ${inputClass}`}
            onChange={handleMinuteFieldChange}
            value={state.minute}
          >
            {getTimeDropdownOptions('minute')}
          </select>
        </div>
      </span>
    );

    return (
      <div className={`form-group datetime-control ${id}-datetime-control ${inputClass}`}>
        <span className={`form-group date-picker--form-group ${inputClass}`}>
          <label htmlFor={id} className={labelClass}>{label}{spacer}</label>
          {dateInput}
        </span>
        {timeControlNode}
      </div>
    );
  } else if (label !== null) {
    return (
      <p className={p_tag_classname}>
        <span className="text-input-component__label"><strong>{label}</strong></span>
        <span>{(value !== null || editable) && !label ? spacer : null}</span>
        <span onBlur={onBlur} onClick={onClick} className={`text-input-component__value ${valueClass}`}>
          {getFormattedDateTime()}
        </span>
        {append}
      </p>
    );
  }

  return (
    <span>{getFormattedDateTime()}</span>
  );
};

DatePicker.propTypes = {
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
};

export default Conditional(InputHOC(DatePicker));
