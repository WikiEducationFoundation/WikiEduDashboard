import React from 'react';
import createReactClass from 'create-react-class';
import PropTypes from 'prop-types';
import Select from 'react-select';
import uuid from 'uuid';
import selectStyles from '../../styles/single_select';

const CourseTypeSelector = createReactClass({
  propTypes: {
    course: PropTypes.object,
    editable: PropTypes.bool,
    updateCourse: PropTypes.func.isRequired
  },

  componentWillMount() {
    this.setState({
      id: uuid.v4(),
      selectedOption: { value: this.props.course.type, label: this._getFormattedCourseType(this.props.course.type) },
    });
  },

  _handleChange(selectedOption) {
    const course = this.props.course;
    const courseType = selectedOption.value;
    course.type = courseType;
    this.setState({ selectedOption });
    if (courseType === 'ClassroomProgramCourse' || course.timeline_enabled) {
      if (!course.timeline_start) {
        course.timeline_start = course.start;
      }
      if (!course.timeline_end) {
        course.timeline_end = course.end;
      }
    }
    return this.props.updateCourse(course);
  },

  _getFormattedCourseType(type) {
    return {
      ClassroomProgramCourse: 'Wikipedia Student Program',
      VisitingScholarship: 'Visiting Scholarship',
      Editathon: 'Edit-a-thon',
      BasicCourse: 'Generic Course',
      ArticleScopedProgram: 'Article Scoped Program',
      FellowsCohort: 'Wikipedia Fellows Cohort'
    }[type];
  },

  render() {
    const currentType = this._getFormattedCourseType(this.props.course.type);
    let selector = (
      <span>
        <strong>Type:</strong> {currentType}
      </span>
    );

    if (this.props.editable && currentType !== 'LegacyCourse') {
      let options = [
        { value: 'BasicCourse', label: this._getFormattedCourseType('BasicCourse') },
        { value: 'Editathon', label: this._getFormattedCourseType('Editathon') },
        { value: 'ArticleScopedProgram', label: this._getFormattedCourseType('ArticleScopedProgram') },
      ];
      if (Features.wikiEd) {
        options = [
          { value: 'ClassroomProgramCourse', label: this._getFormattedCourseType('ClassroomProgramCourse') },
          { value: 'VisitingScholarship', label: this._getFormattedCourseType('VisitingScholarship') },
          { value: 'FellowsCohort', label: this._getFormattedCourseType('FellowsCohort') },
          { value: 'BasicCourse', label: this._getFormattedCourseType('BasicCourse') },
          { value: 'Editathon', label: this._getFormattedCourseType('Editathon') },
          { value: 'ArticleScopedProgram', label: this._getFormattedCourseType('ArticleScopedProgram') },
        ];
      }
      selector = (
        <div className="form-group">
          <label htmlFor={this.state.id}>Type:</label>
          <Select
            id={this.state.id}
            value={options.find(option => option.value === this.state.selectedOption.value)}
            onChange={this._handleChange}
            options={options}
            simpleValue
            styles={selectStyles}
          />
        </div>
      );
    }
    return (
      <div className="course_type_selector">
        {selector}
      </div>
    );
  }
});

export default CourseTypeSelector;

