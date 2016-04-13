import React from 'react';
import CourseActions from '../../actions/course_actions.js';

const CourseTypeSelector = React.createClass({
  propTypes: {
    course: React.PropTypes.object,
    editable: React.PropTypes.bool
  },

  handleChange(e) {
    const course = this.props.course;
    const courseType = e.target.value;
    course.type = courseType;
    CourseActions.updateCourse(course);
  },

  render() {
    const currentType = this.props.course.type;
    let selector = currentType;
    if (this.props.editable && currentType !== 'LegacyCourse') {
      selector = (
        <div className="select_wrapper">
          <select
            name="course_type"
            value={this.props.course.type}
            onChange={this.handleChange}
          >
            <option value="ClassroomProgramCourse">Classroom Program</option>
            <option value="VisitingScholarship">Visiting Scholarship</option>
            <option value="Editathon">Edit-a-thon</option>
            <option value="BasicCourse">Generic Course</option>
          </select>
        </div>
      );
    }
    return (
      <div className="course_type_selector">
        <span>Type: {selector}</span>
      </div>
    );
  }
});

export default CourseTypeSelector;
