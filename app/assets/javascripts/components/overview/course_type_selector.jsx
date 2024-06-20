import React, { useState } from 'react';
import PropTypes from 'prop-types';
import Select from 'react-select';
import uuid from 'uuid';
import selectStyles from '../../styles/single_select';

const CourseTypeSelector = (props) => {
  const _getFormattedCourseType = (type) => {
    return {
      ClassroomProgramCourse: 'Wikipedia Student Program',
      VisitingScholarship: 'Visiting Scholarship',
      Editathon: 'Edit-a-thon',
      BasicCourse: 'Generic Course',
      ArticleScopedProgram: 'Article Scoped Program',
      FellowsCohort: 'Wikipedia Fellows Cohort'
    }[type];
  };

  const id = uuid.v4();
  const [selectedOption, setSelectedOption] = useState({ value: props.course.type, label: _getFormattedCourseType(props.course.type) });

  const _handleChange = (e) => {
    const course = props.course;
    const courseType = e.value;
    course.type = courseType;
    setSelectedOption(e);
    if (courseType === 'ClassroomProgramCourse' || course.timeline_enabled) {
      if (!course.timeline_start) {
        course.timeline_start = course.start;
      }
      if (!course.timeline_end) {
        course.timeline_end = course.end;
      }
    }
    return props.updateCourse(course);
  };

    const currentType = _getFormattedCourseType(props.course.type);
    let selector = (
      <span>
        <strong>Type:</strong> {currentType}
      </span>
    );

    if (props.editable && currentType !== 'LegacyCourse') {
      let options = [
        { value: 'BasicCourse', label: _getFormattedCourseType('BasicCourse') },
        { value: 'Editathon', label: _getFormattedCourseType('Editathon') },
        { value: 'ArticleScopedProgram', label: _getFormattedCourseType('ArticleScopedProgram') },
      ];
      if (Features.wikiEd) {
        options = [
          { value: 'ClassroomProgramCourse', label: _getFormattedCourseType('ClassroomProgramCourse') },
          { value: 'VisitingScholarship', label: _getFormattedCourseType('VisitingScholarship') },
          { value: 'FellowsCohort', label: _getFormattedCourseType('FellowsCohort') },
          { value: 'BasicCourse', label: _getFormattedCourseType('BasicCourse') },
          { value: 'Editathon', label: _getFormattedCourseType('Editathon') },
          { value: 'ArticleScopedProgram', label: _getFormattedCourseType('ArticleScopedProgram') },
        ];
      }
      selector = (
        <div className="form-group">
          <label id={`${id}-label`} htmlFor={id}>{I18n.t('courses.course_type_label')}</label>
          <Select
            id={id}
            value={options.find(option => option.value === selectedOption.value)}
            onChange={_handleChange}
            options={options}
            simpleValue
            styles={selectStyles}
            aria-labelledby={`${id}-label`}
          />
        </div>
      );
    }
    return (
      <div className="course_type_selector">
        {selector}
      </div>
    );
  };
CourseTypeSelector.propTypes = {
  course: PropTypes.object,
  editable: PropTypes.bool,
  updateCourse: PropTypes.func.isRequired
};
export default CourseTypeSelector;
