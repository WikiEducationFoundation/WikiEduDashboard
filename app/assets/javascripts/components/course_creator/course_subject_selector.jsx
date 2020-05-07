import React, { useState, useEffect } from 'react';
import PropTypes from 'prop-types';
import CreatableInput from '../common/creatable_input.jsx';
import TextInput from '../common/text_input.jsx';
import request from '../../utils/request';

const CourseSubjectSelector = ({ updateCourse, subject, editable }) => {
  const [options, setOptions] = useState();
  const [selected, setSelected] = useState(null);
  if (typeof editable !== 'boolean') editable = true;

  useEffect(() => {
    if (editable) {
      // Will contain an array of subjects in the required object format
      const opts = [];

      request('/wizards/researchwrite.json')
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
          if (subject.length > 0) {
            const sel = { value: subject, label: subject };
            setSelected(sel);
            opts.push(sel);
          }
          setOptions(opts);
        });
    }
  }, [editable]);

  return (editable) ? (
    <div className="form-group">
      <CreatableInput
        id="course_subject"
        onChange={({ value }) =>
          updateCourse('subject', value)
        }
        selected={selected}
        label={I18n.t('courses.subject')}
        placeholder={I18n.t('courses.subject')}
        options={options}
      />
    </div>
  ) : (
    <TextInput
      value={subject}
      value_key="courseSubject"
      editable={editable}
      type="text"
      label={I18n.t('courses.subject')}
    />
  );
};

CourseSubjectSelector.propTypes = {
  subject: PropTypes.string,
  updateCourse: PropTypes.func,
  editable: PropTypes.bool
};

export default CourseSubjectSelector;

