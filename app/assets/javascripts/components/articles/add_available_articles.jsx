import React from 'react';
import createReactClass from 'create-react-class';
import PropTypes from 'prop-types';
import TextAreaInput from '../common/text_area_input';
import CourseUtils from '../../utils/course_utils.js';

const AddAvailableArticles = createReactClass({
  displayName: 'AddAvailableArticles',

  propTypes: {
    course_id: PropTypes.string,
    course: PropTypes.object,
    role: PropTypes.number.isRequired,
    current_user: PropTypes.object,
    assignments: PropTypes.array,
    project: PropTypes.string,
    language: PropTypes.string,
    addAssignment: PropTypes.func,
    open: PropTypes.func // closes popover
  },

  getInitialState() {
    return { assignments: '' };
  },

  updateInput(_key, value) {
    return this.setState({ assignments: value });
  },

  resetInput() {
    this.setState({ assignments: '' });
    this.props.open();
  },

  chainSubmissions(assignments, promise) {
    const assignment = assignments.shift();
    if (assignment === undefined) { return promise; }
    let extendedPromise;
    if (promise) {
      extendedPromise = promise.then(() => this.props.addAssignment(assignment));
    } else {
      extendedPromise = this.props.addAssignment(assignment);
    }
    return this.chainSubmissions(assignments, extendedPromise);
  },

  submit() {
    // turn multipline input into an array of lines
    const inputLines = this.state.assignments.match(/[^\r\n]+/g);
    const assignments = inputLines.map((assignmentString) => {
      const assignment = CourseUtils.articleFromTitleInput(assignmentString);
      const language = assignment.language ? assignment.language : this.props.language;
      const project = assignment.project ? assignment.project : this.props.project;
      return {
        title: assignment.title,
        project,
        language,
        course_id: this.props.course_id,
        role: this.props.role
      };
    });
    return this.chainSubmissions(assignments)
      .then(() => this.resetInput());
  },

  render() {
    return (
      <div className="pop__padded-content">
        <TextAreaInput
          id="add_available_articles"
          onChange={this.updateInput}
          value={this.state.assignments}
          value_key="assignments"
          editable
          placeholder={I18n.t('assignments.add_available_placeholder')}
        />
        <button className="button border pull-right" onClick={this.submit}>{I18n.t('assignments.add_available_submit')}</button>
      </div>
    );
  }
});

export default AddAvailableArticles;
