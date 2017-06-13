import React from 'react';
import CourseActions from '../../actions/course_actions.js';
import uuid from 'uuid';

const SubmittedSelector = React.createClass({
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
        <strong>Submitted:</strong> {currentValue ? 'yes' : 'no'}
      </span>
    );
    if (this.props.editable) {
      selector = (
        <div className="form-group">
          <label htmlFor={this.state.id}>Submitted:</label>
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
