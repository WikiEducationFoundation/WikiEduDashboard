import React, { useState } from 'react';
import PropTypes from 'prop-types';
import Select from 'react-select';
import selectStyles from '../../styles/single_select';

const YesNoSelector = (props) => {
    const initialState = props.course[props.courseProperty] ? I18n.t('application.opt_yes') : I18n.t('application.opt_no');
    const [selectedOption, setSelectedOption] = useState({ value: initialState, label: initialState });

  const _handleChange = (e) => {
    const course = props.course;
    const value = e.value;
    setSelectedOption(e);
    if (value === I18n.t('application.opt_yes')) {
      course[props.courseProperty] = true;
    } else if (value === I18n.t('application.opt_no')) {
      course[props.courseProperty] = false;
    }
    return props.updateCourse(course);
  };

  const currentValue = props.course[props.courseProperty];
  let selector = (
    <span>
      <strong>{props.label}:</strong> {currentValue ? I18n.t('application.opt_yes') : I18n.t('application.opt_no')}
    </span>
  );
  if (props.editable) {
    let tooltip;
    if (props.tooltip) {
      tooltip = (
        <div className="tooltip-trigger">
          <img src ="/assets/images/info.svg" alt = "tooltip default logo" />
          <div className="tooltip large dark">
            <p>
              {props.tooltip}
            </p>
          </div>
        </div>
      );
    }
    const options = [
      { value: I18n.t('application.opt_yes'), label: I18n.t('application.opt_yes') },
      { value: I18n.t('application.opt_no'), label: I18n.t('application.opt_no') }
    ];
    selector = (
      <div className="form-group">
        <label
          id={`${props.courseProperty}-label`}
          className="inline-label"
          htmlFor={`${props.courseProperty}Toggle`}
        >
          <strong>{props.label}:</strong>
        </label>
        {tooltip}
        <Select
          id={`${props.courseProperty}Toggle`}
          name={props.courseProperty}
          value={options.find(option => option.value === selectedOption.value)}
          onChange={_handleChange}
          options={options}
          styles={selectStyles}
          aria-labelledby={`${props.courseProperty}-label`}
        />
      </div>
    );
  }
  return (
    <div className={`${props.courseProperty}_selector`}>
      {selector}
    </div>
  );
};

YesNoSelector.propTypes = {
  courseProperty: PropTypes.string.isRequired,
  label: PropTypes.string.isRequired,
  tooltip: PropTypes.string,
  course: PropTypes.object.isRequired,
  editable: PropTypes.bool,
  updateCourse: PropTypes.func.isRequired
};
export default YesNoSelector;
