import React from 'react';
import createReactClass from 'create-react-class';
import PropTypes from 'prop-types';
import CourseActions from '../../actions/course_actions.js';
import uuid from 'uuid';

const TimelineToggle = createReactClass({
  propTypes: {
    course: PropTypes.object,
    editable: PropTypes.bool
  },

  componentWillMount() {
    this.setState({
      id: uuid.v4()
    });
  },

  _handleChange(e) {
    const course = this.props.course;
    const timelineEnabled = e.target.value;
    if (timelineEnabled === 'yes') {
      course.timeline_enabled = true;
    } else if (timelineEnabled === 'no') {
      course.timeline_enabled = false;
    }
    CourseActions.updateCourse(course);
  },

  render() {
    const currentValue = this.props.course.timeline_enabled;
    let selector = (
      <span>
        <strong>{I18n.t("courses.timeline_enabled")}:</strong> {currentValue ? 'yes' : 'no'}
      </span>
    );
    if (this.props.editable) {
      selector = (
        <div className="form-group">
          <span htmlFor={this.state.id}>
            <strong>{I18n.t("courses.timeline_enabled")}:</strong>
          </span>
          <select
            id={this.state.id}
            name="timeline_enabled"
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
      <div className="timeline_toggle">
        {selector}
      </div>
    );
  }
});

export default TimelineToggle;
