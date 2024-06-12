import React from 'react';
import PropTypes from 'prop-types';
import Select from 'react-select';
import selectStyles from '../../styles/single_select';

const CourseLevelSelector = ({ level, updateCourse }) => {
  let selectedOption = { value: level, label: level };
  const handleChange = (option) => {
    const courseLevel = option.value;
    selectedOption = option;
    updateCourse('level', courseLevel);
  };
  const options = [
    { value: '', label: '— select one —' },
    { value: 'Introductory', label: 'Introductory' },
    { value: 'Advanced Undergrad', label: 'Advanced undergraduate' },
    { value: 'Graduate', label: 'Graduate' },
  ];
  return (
    <div className="form-group">
      <label id="course_level-label" htmlFor="course_level">Course level:</label>
      <Select
        id="course_level"
        value={options.find(option => option.value === selectedOption.value)}
        onChange={handleChange}
        options={options}
        simpleValue
        styles={selectStyles}
        aria-labelledby="course_level-label"
      />
    </div>
  );
};

CourseLevelSelector.propTypes = {
  level: PropTypes.string,
  updateCourse: PropTypes.func
};

export default CourseLevelSelector;
