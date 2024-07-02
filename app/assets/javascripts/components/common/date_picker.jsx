import React, { useState, useEffect, useRef } from 'react';
import PropTypes from 'prop-types';
import DayPicker from 'react-day-picker';
import { range, includes } from 'lodash-es';
import {
  startOfDay,
  endOfDay,
  isValid,
  isAfter,
  parseISO,
  setHours,
  setMinutes,
  formatISO,
} from 'date-fns';
import InputHOC from '../high_order/input_hoc.jsx';
import Conditional from '../high_order/conditional.jsx';
import CourseDateUtils from '../../utils/course_date_utils.js';
import { formatDateWithoutTime, toDate } from '../../utils/date_utils.js';
import onClickOutside from 'react-onclickoutside';

const DatePicker = ({
  id,
  value: propValue,
  spacer,
  label,
  timeLabel,
  valueClass,
  editable,
  enabled,
  focus,
  inline,
  placeholder,
  p_tag_classname,
  onBlur,
  onChange,
  onClick,
  append,
  date_props,
  showTime,
  value_key,
}) => {
  const [selectedValue, setSelectedValue] = useState(
    propValue ? formatDateWithoutTime(toDate(propValue)) : ''
  );
  const [hour, setHour] = useState(0);
  const [minute, setMinute] = useState(0);
  const [datePickerVisible, setDatePickerVisible] = useState(false);
  const datePickerRef = useRef(null);

  DatePicker.handleClickOutside = () => setDatePickerVisible(false);

  useEffect(() => {
    if (editable && datePickerRef.current) {
      if (datePickerVisible) {
        datePickerRef.current.focus();
      } else if (datePickerRef.current.blur) {
        datePickerRef.current.blur();
      }
    }
  }, [datePickerVisible, editable]);

  const handleDatePickerChange = (selectedDate) => {
    const date = toDate(selectedDate);
    if (isDayDisabled(date)) {
      return;
    }
    datePickerRef.current.focus();
    setSelectedValue(formatDateWithoutTime(date));
    setDatePickerVisible(false);
    onChangeHandler();
  };

  const handleDateFieldChange = (e) => {
    const { value: newValue } = e.target;
    if (newValue !== selectedValue) {
      setSelectedValue(newValue);
    }
  };

  const handleDateFieldBlur = (e) => {
    const { value: newValue } = e.target;
    if (isValidDate(newValue) && !isDayDisabled(parseISO(newValue))) {
      setSelectedValue(newValue);
      onChangeHandler();
    } else {
      setSelectedValue(formatDateWithoutTime(toDate(propValue)));
    }
  };

  const handleHourFieldChange = (e) => {
    if (selectedValue === '') {
      handleDatePickerChange(new Date());
    }
    setHour(e.target.value);
    onChangeHandler();
  };

  const handleMinuteFieldChange = (e) => {
    if (selectedValue === '') {
      handleDatePickerChange(new Date());
    }
    setMinute(e.target.value);
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
    return currentDate === selectedValue;
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
  };

  const isValidDate = (value) => {
    const validationRegex = /^20\d\d-(0?[1-9]|1[012])-(0?[1-9]|[12][0-9]|3[01])/;
    return validationRegex.test(value) && isValid(toDate(value));
  };

  const onChangeHandler = () => {
    const e = { target: { value: formatISO(getDate()) } };
    onChange(e);
  };

  const getDate = () => {
    let dateObj = toDate(selectedValue);
    dateObj = setHours(dateObj, hour);
    return setMinutes(dateObj, minute);
  };

  const getFormattedDateTime = () => {
    return CourseDateUtils.formattedDateTime(getDate(), showTime);
  };

  const getTimeDropdownOptions = (type) => {
    return range(0, type === 'hour' ? 24 : 60).map((value) => {
      return (
        <option value={value} key={`timedropdown-${type}-${value}`}>
          {`00${value}`.slice(-2)}
        </option>
      );
    });
  };

  const spacerText = spacer || ': ';
  let labelText = label || '';
  labelText += spacerText;
  let timeLabelText = timeLabel || '';
  timeLabelText += spacerText;

  const labelClass = '';
  let inputClass = inline !== null && inline ? ' inline' : '';

  if (valueClass) {
    inputClass += ` ${valueClass}`;
  }

  if (editable) {
    let minDate;
    if (date_props && date_props.minDate) {
      if (isValid(date_props.minDate)) {
        minDate = date_props.minDate;
      }
    }

    const date = parseISO(selectedValue);
    const currentMonth = isValid(date) ? date : minDate || new Date();

    const modifiers = {
      selected: isDaySelected,
      disabled: isDayDisabled,
    };

    const dateInput = (
      <div className="date-input" ref={datePickerRef}>
        <input
          id={id}
          value={selectedValue || ''}
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

        {datePickerVisible && (
          <DayPicker
            className="DayPicker--visible ignore-react-onclickoutside"
            modifiers={modifiers}
            disabledDays={isDayDisabled}
            onDayClick={handleDatePickerChange}
            month={currentMonth}
          />
        )}
      </div>
    );

    const timeControlNode = (
      <span className={`form-group time-picker--form-group ${inputClass}`}>
        <label htmlFor={`${id}-hour`} className={labelClass}>
          {timeLabelText}
        </label>
        <div className="time-input">
          <select
            className={`time-input__hour ${inputClass}`}
            onChange={handleHourFieldChange}
            value={hour}
          >
            {getTimeDropdownOptions('hour')}
          </select>
          :
          <select
            className={`time-input__minute ${inputClass}`}
            onChange={handleMinuteFieldChange}
            value={minute}
          >
            {getTimeDropdownOptions('minute')}
          </select>
        </div>
      </span>
    );

    return (
      <div
        className={`form-group datetime-control ${id}-datetime-control ${inputClass}`}
      >
        <span className={`form-group date-picker--form-group ${inputClass}`}>
          <label htmlFor={id} className={labelClass}>
            {labelText}
          </label>
          {dateInput}
        </span>
        {showTime ? timeControlNode : null}
      </div>
    );
  } else if (label !== null) {
    return (
      <p className={p_tag_classname}>
        <span className="text-input-component__label">
          <strong>{labelText}</strong>
        </span>
        <span>
          {(propValue !== null || editable) && !label ? spacerText : null}
        </span>
        <span onBlur={onBlur} onClick={onClick} className={valueClass}>
          {getFormattedDateTime()}
        </span>
        {append}
      </p>
    );
  }

  return <span>{getFormattedDateTime()}</span>;
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
  placeholder: PropTypes.string,
  p_tag_classname: PropTypes.string,
  onBlur: PropTypes.func,
  onChange: PropTypes.func.isRequired,
  onClick: PropTypes.func,
  append: PropTypes.string,
  date_props: PropTypes.object,
  showTime: PropTypes.bool,
};

const clickOutsideConfig = {
  handleClickOutside: () => DatePicker.handleClickOutside,
};

export default onClickOutside(
  Conditional(InputHOC(DatePicker)),
  clickOutsideConfig
);
