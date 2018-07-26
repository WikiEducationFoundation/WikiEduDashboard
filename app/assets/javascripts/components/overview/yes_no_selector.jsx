import React from 'react';
import createReactClass from 'create-react-class';
import PropTypes from 'prop-types';
import CourseActions from '../../actions/course_actions.js';

const YesNoSelector = createReactClass({
  propTypes: {
    courseProperty: PropTypes.string.isRequired,
    label: PropTypes.string.isRequired,
    tooltip: PropTypes.string,
    course: PropTypes.object.isRequired,
    editable: PropTypes.bool,
    updateCourse: PropTypes.func.isRequired
  },

  _handleChange(e) {
    const course = this.props.course;
    const value = e.target.value;
    if (value === 'yes') {
      course[this.props.courseProperty] = true;
    } else if (value === 'no') {
      course[this.props.courseProperty] = false;
    }
    this.props.updateCourse(course);
    CourseActions.updateCourse(course);
  },

  render() {
    const currentValue = this.props.course[this.props.courseProperty];
    let selector = (
      <span>
        <strong>{this.props.label}:</strong> {currentValue ? 'yes' : 'no'}
      </span>
    );
    if (this.props.editable) {
      let tooltip;
      if (this.props.tooltip) {
        tooltip = (
          <div className="tooltip-trigger">
            <img src ="/assets/images/info.svg" alt = "tooltip default logo" />
            <div className="tooltip large dark">
              <p>
                {this.props.tooltip}
              </p>
            </div>
          </div>
        );
      }

      selector = (
        <div className="form-group">
          <span htmlFor={`${this.props.courseProperty}Toggle`}>
            <strong>{this.props.label}:</strong>
          </span>
          {tooltip}
          <select
            id={`${this.props.courseProperty}Toggle`}
            name={this.props.courseProperty}
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
      <div className={`${this.props.courseProperty}_selector`}>
        {selector}
      </div>
    );
  }
});

export default YesNoSelector;
