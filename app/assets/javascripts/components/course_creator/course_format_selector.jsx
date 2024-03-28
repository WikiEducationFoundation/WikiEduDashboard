import React from 'react';
import PropTypes from 'prop-types';
import Select from 'react-select';
import selectStyles from '../../styles/single_select';

const CourseFormatSelector = ({ format, updateCourse }) => {
  let selectedOption = { value: format, label: format };
  const handleChange = (option) => {
    const courseLevel = option.value;
    selectedOption = option;
    updateCourse('format', courseLevel);
  };
  const options = [
    { value: '', label: '— select one —' },
    { value: 'In-person', label: 'In-person' },
    { value: 'Online synchronous', label: 'Online synchronous' },
    { value: 'Online asynchronous', label: 'Online asynchronous' },
    { value: 'Mixed', label: 'Mixed' },
  ];
  return (
    <div className="form-group">
      <label htmlFor="course_format">Course format:</label>
      <Select
        id="course_format"
        value={options.find(option => option.value === selectedOption.value)}
        onChange={handleChange}
        options={options}
        simpleValue
        styles={selectStyles}
      />
    </div>
  );
};

CourseFormatSelector.propTypes = {
  format: PropTypes.string,
  updateCourse: PropTypes.func
};

export default CourseFormatSelector;
