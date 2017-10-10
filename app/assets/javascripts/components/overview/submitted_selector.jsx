import React from 'react';
import createReactClass from 'create-react-class';
import PropTypes from 'prop-types';
import CourseActions from '../../actions/course_actions.js';
import uuid from 'uuid';

const SubmittedSelector = createReactClass({
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
    const submitted = e.target.value;
    if (submitted === 'yes') {
      course.submitted = true;
    } else if (submitted === 'no') {
      course.submitted = false;
    }
    CourseActions.updateCourse(course);
  },

  render() {
    const currentValue = this.props.course.submitted;
    let selector = (
      <span>
        <strong>{I18n.t("courses.submitted")}:</strong> {currentValue ? 'yes' : 'no'}
      </span>
    );
    if (this.props.editable) {
      selector = (
        <div className="form-group">
          <span htmlFor={this.state.id}>
            <strong>{I18n.t("courses.submitted")}:</strong>
          </span>
          <div className="tooltip-trigger">
            <img src ="/assets/images/info.svg" alt = "tooltip default logo" />
            <div className="tooltip large dark">
              <p>
                {I18n.t("courses.course_submitted")}
              </p>
            </div>
          </div>
          <select
            id={this.state.id}
            name="submitted"
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
      <div className="submitted_selector">
        {selector}
      </div>
    );
  }
});

export default SubmittedSelector;
