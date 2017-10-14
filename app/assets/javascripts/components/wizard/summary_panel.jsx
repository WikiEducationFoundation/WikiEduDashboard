// use WizardStore.getPanels() for answers
import React from 'react';
import createReactClass from 'create-react-class';
import PropTypes from 'prop-types';
import ServerActions from '../../actions/server_actions.js';
import WizardActions from '../../actions/wizard_actions.js';
import WizardStore from '../../stores/wizard_store.js';
import Panel from './panel.jsx';

import { browserHistory } from 'react-router';

const SummaryPanel = createReactClass({
  displayName: 'SummaryPanel',

  propTypes: {
    courseId: PropTypes.string,
    course: PropTypes.object.isRequired,
    wizardId: PropTypes.string
  },

  submit() {
    ServerActions.submitWizard(this.props.courseId, this.props.wizardId, WizardStore.getOutput());
    return browserHistory.push(`/courses/${this.props.courseId}/timeline`);
  },
  rewind(toIndex) {
    return WizardActions.rewindWizard(toIndex);
  },
  render() {
    const rawOptions = WizardStore.getAnswers().map((answer, i) => {
      // summary of the Course Dates panel
      let details;
      if (i === 0) {
        details = [
          <p key={'course_dates_summary'}>
            {I18n.t('timeline.course_start')}— {this.props.course.start} <br />
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
