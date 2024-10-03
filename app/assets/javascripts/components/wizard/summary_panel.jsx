import React from 'react';
import PropTypes from 'prop-types';
import withRouter from '../util/withRouter';
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

const SummaryPanel = (props) => {
  const submit = () => {
    props.submitWizard(props.courseId);
    window.onbeforeunload = window.onbeforeunloadcache;
    return props.router.navigate(`/courses/${props.courseId}/timeline`);
  };

  const rewind = (toIndex) => {
    props.goToWizard(toIndex);
    window.location.hash = `step${toIndex + 1}`; // Sync Step Changes
    document.title = document.title.replace(/\d+$/, toIndex + 1); // Sync Title
  };

  let answers = [];
  if (props.active) {
    answers = answersFromPanels(props.panels);
  }
  const rawOptions = answers.map((answer, i) => {
    // summary of the Course Dates panel
    let details;
    if (i === 0) {
      details = [
        <p key={'course_dates_summary'}>
          {I18n.t('timeline.course_start')} — {props.course.start} <br />
          {I18n.t('timeline.course_end')} — {props.course.end} <br />
          {I18n.t('courses.assignment_start')} — {props.course.timeline_start} <br />
          {I18n.t('courses.assignment_end')} — {props.course.timeline_end}
        </p>
      ];
    } else {
      details = answer.selections.map((selection, j) => <p key={`detail${i}${j}`}>{selection}</p>);
    }
    return (
      <button key={`answer${i}`} className="wizard__option summary" onClick={rewind.bind(this, i)}>
        <h3>{answer.title}</h3>
        {details}
        <p className="edit">Edit</p>
      </button>
    );
  }
  );

  return (
    <Panel
      {...props}
      advance={submit}
      raw_options={rawOptions}
      button_text="Generate Timeline"
    />
  );
};
SummaryPanel.displayName = 'SummaryPanel';
SummaryPanel.propTypes = {
  courseId: PropTypes.string,
  course: PropTypes.object.isRequired,
  panels: PropTypes.array.isRequired
};

export default withRouter(SummaryPanel);
