import React from 'react';
import createReactClass from 'create-react-class';
import PropTypes from 'prop-types';
import { browserHistory } from 'react-router';
import Panel from './panel.jsx';

const answersFromPanels = (panels) => {
  const answers = [];
  panels.forEach((panel, i) => {
    if (i === panels.length - 1) { return; }
    const answer = { title: panel.title, selections: [] };
    if (panel.options !== undefined && panel.options.length > 0) {
      panel.options.map((option) => {
        if (option.selected) { return answer.selections.push(option.title); }
        return undefined;
      });
      if (answer.selections.length === 0) { answer.selections = ['No selections']; }
    }
    return answers.push(answer);
  });
  return answers;
};

const SummaryPanel = createReactClass({
  displayName: 'SummaryPanel',

  propTypes: {
    courseId: PropTypes.string,
    course: PropTypes.object.isRequired,
    panels: PropTypes.array.isRequired
  },

  submit() {
    this.props.submitWizard(this.props.courseId);
    window.onbeforeunload = null;
    return browserHistory.push(`/courses/${this.props.courseId}/timeline`);
  },
  rewind(toIndex) {
    this.props.goToWizard(toIndex);
    window.location.hash = `step${toIndex + 1}`; // Sync Step Changes
    document.title = document.title.replace(/\d+$/, toIndex + 1); // Sync Title
  },
  render() {
    let answers = [];
    if (this.props.active) {
      answers = answersFromPanels(this.props.panels);
    }
    const rawOptions = answers.map((answer, i) => {
      // summary of the Course Dates panel
      let details;
      if (i === 0) {
        details = [
          <p key={'course_dates_summary'}>
            {I18n.t('timeline.course_start')} — {this.props.course.start} <br />
            {I18n.t('timeline.course_end')} — {this.props.course.end} <br />
            {I18n.t('courses.assignment_start')} — {this.props.course.timeline_start} <br />
            {I18n.t('courses.assignment_end')} — {this.props.course.timeline_end}
          </p>
        ];
      } else {
        details = answer.selections.map((selection, j) => <p key={`detail${i}${j}`}>{selection}</p>);
      }
      return (
        <button key={`answer${i}`} className="wizard__option summary" onClick={this.rewind.bind(this, i)}>
          <h3>{answer.title}</h3>
          {details}
          <p className="edit">Edit</p>
        </button>
      );
    }
    );

    return (
      <Panel
        {...this.props}
        advance={this.submit}
        raw_options={rawOptions}
        button_text="Generate Timeline"
      />
    );
  }
});

export default SummaryPanel;
