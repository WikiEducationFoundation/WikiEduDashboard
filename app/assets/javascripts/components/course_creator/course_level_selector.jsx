import React from 'react';

const CourseLevelSelector = ({ level, updateCourse }) => {
  const handleChange = (e) => {
    const courseLevel = e.target.value;
    updateCourse('level', courseLevel);
  };

  return (
    <div className="form-group">
      <label htmlFor="course_level">Course level:</label>
      <select
        id="course_level"
        name="course_level"
        value={level}
        onChange={handleChange}
      >
        <option disabled value=""> — select one —</option>
        <option value="introductory">Introductory</option>
        <option value="advanced undergraduate">Advanced undergraduate</option>
        <option value="graduate">Graduate</option>
      </select>
    </div>
  );
};

CourseLevelSelector.propTypes = {
  level: React.PropTypes.string,
  updateCourse: React.PropTypes.func
};

export default CourseLevelSelector;
