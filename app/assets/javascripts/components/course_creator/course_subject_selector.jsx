import React, { useState, useEffect } from 'react';
import PropTypes from 'prop-types';
import Select from 'react-select';
import selectStyles from '../../styles/single_select';

const CourseSubjectSelector = ({ subject, updateCourse }) => {
  const [options, setOptions] = useState();
  let selectedOption = { value: subject, label: subject };

  const handleChange = (option) => {
    selectedOption = option;
    const courseSubject = selectedOption.value;
    updateCourse('subject', courseSubject);
  };

  useEffect(() => {
    const opts = [];

    fetch('/wizards/researchwrite.json')
      .then(resp => resp.json())
      .then((data) => {
        const jsonObj = data;
        const jsonObjects = jsonObj[5].options;

        Object.keys(jsonObjects).forEach((key) => {
          if (jsonObjects.hasOwnProperty(key)) {
            opts.push({
              value: jsonObjects[key].title,
              label: jsonObjects[key].title
            });
          }
        });
        setOptions(opts);
      });
  }, []);

  return (
    <div className="form-group">
      <label htmlFor="course_subject">Course Subject:</label>
      <Select
        id="course_subject"
        onChange={handleChange}
        options={options}
        simpleValue
        styles={selectStyles}
      />
    </div>
  );
};

CourseSubjectSelector.propTypes = {
  subject: PropTypes.string,
  updateCourse: PropTypes.func
};

export default CourseSubjectSelector;

