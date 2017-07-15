import React from 'react';
import CourseActions from '../../actions/course_actions.js';
import uuid from 'uuid';

const CourseTypeSelector = React.createClass({
  propTypes: {
    course: React.PropTypes.object,
    editable: React.PropTypes.bool
  },

  componentWillMount() {
    this.setState({
      id: uuid.v4()
    });
  },

  _handleChange(e) {
    const course = this.props.course;
    const courseType = e.target.value;
    course.type = courseType;
    if (courseType === 'ClassroomProgramCourse') {
      if (!course.timeline_start) {
        course.timeline_start = course.start;
      }
      if (!course.timeline_end) {
        course.timeline_end = course.end;
      }
    }
    CourseActions.updateCourse(course);
  },

  _getFormattedCourseType(type) {
    return {
      ClassroomProgramCourse: 'Classroom Program',
      VisitingScholarship: 'Visiting Scholarship',
      Editathon: 'Edit-a-thon',
      BasicCourse: 'Generic Course'
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
      selector = (
        <div className="form-group">
          <label htmlFor={this.state.id}>Type:</label>
          <select
            id={this.state.id}
            name="course_type"
            value={this.props.course.type}
            onChange={this._handleChange}
          >
            <option value="ClassroomProgramCourse">{this._getFormattedCourseType('ClassroomProgramCourse')}</option>
            <option value="VisitingScholarship">{this._getFormattedCourseType('VisitingScholarship')}</option>
            <option value="Editathon">{this._getFormattedCourseType('Editathon')}</option>
            <option value="BasicCourse">{this._getFormattedCourseType('BasicCourse')}</option>
          </select>
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
