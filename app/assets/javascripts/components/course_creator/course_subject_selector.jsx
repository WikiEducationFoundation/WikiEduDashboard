import React, { useState, useEffect } from 'react';
import PropTypes from 'prop-types';
import Select from 'react-select';
import selectStyles from '../../styles/single_select';

const CourseSubjectSelector = ({ subject, updateCourse }) => {
  const [options, setOptions] = useState();
  let selectedOption = { value: subject, label: subject };

  const handleChange = option => {
    const courseSubject = option.value;
    selectedOption = option;
    updateCourse('subject', courseSubject);
  };

  useEffect(() => {
    let opts = [];

    fetch('/wizards/researchwrite.json')
      .then(resp => resp.json())
      .then(data => {
        const jsonObj = data;

        for (var value in jsonObj[5].options) {
          if (jsonObj[5].options.hasOwnProperty(value)) {
            opts.push({
              value: jsonObj[5].options[value].title,
              label: jsonObj[5].options[value].title
            });
          }
        }
        setOptions(opts);
      });
  }, []);

  return (
    <div className='form-group'>
      <label htmlFor='course_subject'>Course Subject:</label>
      <Select
        id='course_subject'
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
