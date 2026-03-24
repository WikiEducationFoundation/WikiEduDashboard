import React, { useState } from 'react';
import Select from 'react-select';
import PropTypes from 'prop-types';

const CampaignCourseSearch = ({ initialCourses, courseStringPrefix, courseOptions }) => {
  const [selectedCourses, setSelectedCourses] = useState(initialCourses || []);

  const handleChange = (selectedOptions) => {
    setSelectedCourses(selectedOptions || []);
  };

  const prefix = courseStringPrefix || 'courses';

  return (
    <div className="course-title-select-wrapper">
      <Select
        isMulti
        options={courseOptions || []}
        onChange={handleChange}
        value={selectedCourses}
        placeholder={`${I18n.t(`${prefix}.course`)}...`}
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
  initialCourses: PropTypes.array,
  courseStringPrefix: PropTypes.string,
  courseOptions: PropTypes.array
};

export default CampaignCourseSearch;
