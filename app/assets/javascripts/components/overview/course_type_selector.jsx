import React from 'react';

const CourseTypeSelector = React.createClass({
  propTypes: {
    course: React.PropTypes.object,
    editable: React.PropTypes.bool
  },

  render() {
    const currentType = this.props.course.type;
    let selector = currentType;
    if (this.props.editable && currentType !== 'LegacyCourse') {
      selector = (
        <div className="select_wrapper">
          <select name="course_type" defaultValue={this.props.course.type}>
            <option value="ClassroomProgramCourse" key="ClassroomProgramCourse">Classroom Program</option>
            <option value="VisitingScholarship" key="VisitingScholarship">Visiting Scholarship</option>
            <option value="Editathon" key="Editathon">Edit-a-thon</option>
            <option value="BasicCourse" key="BasicCourse">Generic Course</option>
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
