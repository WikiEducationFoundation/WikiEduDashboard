import React, { useState } from 'react';
import AsyncSelect from 'react-select/async';
import PropTypes from 'prop-types';

const CampaignCourseSearch = ({ initialCourses }) => {
  const [selectedCourses, setSelectedCourses] = useState(initialCourses || []);

  const loadOptions = (inputValue, callback) => {
    if (inputValue.length < 3) {
      callback([]);
      return;
    }

    fetch(`/courses/search.json?search=${encodeURIComponent(inputValue)}`)
      .then(response => response.json())
      .then((data) => {
        if (data.courses && data.courses.length > 0) {
          const options = data.courses.map(course => ({
            value: course.title,
            label: course.title
          }));
          callback(options);
        } else {
          callback([]);
        }
      })
      .catch(() => {
        callback([]);
      });
  };

  const handleChange = (selectedOptions) => {
    setSelectedCourses(selectedOptions || []);
  };

  return (
    <div className="course-title-select-wrapper">
      <AsyncSelect
        isMulti
        loadOptions={loadOptions}
        onChange={handleChange}
        value={selectedCourses}
        placeholder={`${I18n.t('courses.course')}...`}
        noOptionsMessage={() => I18n.t('application.search_results.none')}
        className="campaign-course-search"
      />

      {/* Hidden inputs to allow the standard Rails form submission to work */}
      {selectedCourses.map((course, index) => (
        <input
          key={index}
          type="hidden"
          name="course_title[]"
          value={course.value || ''}
        />
      ))}
    </div>
  );
};

CampaignCourseSearch.propTypes = {
  initialCourses: PropTypes.array
};

export default CampaignCourseSearch;
