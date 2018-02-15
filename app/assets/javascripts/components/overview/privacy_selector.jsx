import React from 'react';
import createReactClass from 'create-react-class';
import PropTypes from 'prop-types';
import uuid from 'uuid';
import CourseActions from '../../actions/course_actions.js';

const PrivacySelector = createReactClass({
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
    const privateCourse = e.target.value;
    if (privateCourse === 'yes') {
      course.private = true;
    } else if (privateCourse === 'no') {
      course.private = false;
    }
    CourseActions.updateCourse(course);
  },

  render() {
    const currentValue = this.props.course.private;
    let selector = (
      <span>
        <strong>{I18n.t("courses.private")}:</strong> {currentValue ? 'yes' : 'no'}
      </span>
    );
    if (this.props.editable) {
      selector = (
        <div className="form-group">
          <span htmlFor={this.state.id}>
            <strong>{I18n.t("courses.private")}:</strong>
          </span>
          <select
            id={this.state.id}
            name="private"
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
      <div className="private_selector">
        {selector}
      </div>
    );
  }
});

export default PrivacySelector;
