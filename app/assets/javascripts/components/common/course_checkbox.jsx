import React from 'react';

const CourseCheckbox = (props) => {
  const checkboxId = `course_${props.checkboxFor}`;
  const updateCourseProps = (e) => {
    const isChecked = e.target.checked;
    props.updateCourseProps({ [props.checkboxFor]: isChecked });
  };

  return (
    <div className="form-group">
      <label htmlFor={checkboxId}>
        <input
          id={checkboxId}
          type="checkbox"
          value={props.value}
          onChange={updateCourseProps}
          checked={props.checked}
        />
        {props.text}
      </label>
    </div>
  );
};

export default CourseCheckbox;
