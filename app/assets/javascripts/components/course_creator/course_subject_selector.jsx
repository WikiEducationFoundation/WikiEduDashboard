import React, { useState, useEffect } from 'react';
import PropTypes from 'prop-types';
import CreatableInput from '../common/creatable_input.jsx';

const CourseSubjectSelector = ({ updateCourse }) => {
  const [options, setOptions] = useState();

  useEffect(() => {
    // Will contain an array of subjects in the required object format
    const opts = [];

    fetch('/wizards/researchwrite.json')
      .then(resp => resp.json())
      .then((data) => {
        const jsonObj = data;
        // Exctracting the 5th index of researchwrite.json that contains all the subjects
        const subjectOptions = jsonObj[5].options;
        Object.keys(subjectOptions).forEach((key) => {
          if (subjectOptions.hasOwnProperty(key)) {
            opts.push({
              value: subjectOptions[key].title,
              label: subjectOptions[key].title
            });
          }
        });
        setOptions(opts);
      });
  }, []);

  return (
    <div className="form-group">
      <CreatableInput
        id="course_subject"
        onChange={({ value }) =>
          updateCourse('subject', value)
        }
        label={'Course Subject:'}
        placeholder={'Subject'}
        options={options}
      />
    </div>
  );
};

CourseSubjectSelector.propTypes = {
  subject: PropTypes.string,
  updateCourse: PropTypes.func
};

export default CourseSubjectSelector;




