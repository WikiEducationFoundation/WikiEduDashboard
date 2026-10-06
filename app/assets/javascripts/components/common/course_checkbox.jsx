import React from 'react';

const CourseCheckbox = (props) => {
  const checkboxId = `course_${props.checkboxFor}`;
  const tooltipId = `${checkboxId}_tooltip`;
  const updateCourseProps = (e) => {
    const isChecked = e.target.checked;
    props.updateCourseProps({ [props.checkboxFor]: isChecked });
  };

  // With tooltipText, the whole row is the tooltip trigger: hovering it, or
  // focusing the checkbox, shows the tooltip, and aria-describedby gives screen
  // readers the same text when the checkbox takes focus.
  let infoIcon;
  let tooltip;
  if (props.tooltipText) {
    infoIcon = <img className="course-checkbox__info" src="/assets/images/info.svg" alt="" />;
    tooltip = (
      <div className="tooltip large dark" role="tooltip" id={tooltipId}>
        <p>{props.tooltipText}</p>
      </div>
    );
  }

  return (
    <div className={`form-group course-checkbox${tooltip ? ' tooltip-trigger' : ''}`}>
      <label htmlFor={checkboxId}>
        <input
          id={checkboxId}
          type="checkbox"
          value={props.value}
          onChange={updateCourseProps}
          checked={props.checked}
          aria-describedby={tooltip ? tooltipId : undefined}
        />
        {props.text}
        {infoIcon}
      </label>
      {tooltip}
    </div>
  );
};

export default CourseCheckbox;
