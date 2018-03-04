import React from 'react';
import CourseActions from '../../actions/course_actions.js';
import uuid from 'uuid';

const CourseEditToggle = React.createClass({
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
    const courseEditEnabled = e.target.value;
    if (courseEditEnabled === 'yes') {
      course.course_edit_enabled = true;
    } else if (courseEditEnabled === 'no') {
      course.course_edit_enabled = false;
    }
    CourseActions.updateCourse(course);
  },

  render() {
    const currentValue = this.props.course.course_edit_enabled;
    let selector = (
      <span>
        <strong>{I18n.t("courses.course_edit_enabled")}:</strong> {currentValue ? 'yes' : 'no'}
      </span>
    );
    if (this.props.editable) {
      selector = (
        <div className="form-group">
          <span htmlFor={this.state.id}>
            <strong>{I18n.t("courses.course_edit_enabled")}:</strong>
          </span>
          <select
            id={this.state.id}
            name="course_edit_enabled"
            value={currentValue ? 'yes' : 'no'}
            onChange={this._handleChange}
          >
            <option value="yes">yes</option>
            <option value="no">no</option>
          </select>
        </div>
      );
    }
    return (
      <div className="course_edit_toggle">
        {selector}
      </div>
    );
  }
});

export default CourseEditToggle;