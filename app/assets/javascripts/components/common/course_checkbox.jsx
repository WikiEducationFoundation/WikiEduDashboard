import React from 'react';

const CourseCheckbox = (props) => {
    return (
      <div className="form-group">
        <label htmlFor={props.label}>
          <input
            id={props.checkbox_id}
            type="checkbox"
            value={props.value}
            onChange={props.onChange}
            checked={props.checked}
          />
          {props.text}
        </label>
      </div>
    );
};

export default CourseCheckbox;
