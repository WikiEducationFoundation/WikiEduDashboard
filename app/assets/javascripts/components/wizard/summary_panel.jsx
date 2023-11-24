import React, { useEffect } from 'react';
import PropTypes from 'prop-types';
import withRouter from '../util/withRouter';
import Panel from './panel.jsx';

const answersFromPanels = (panels) => {
  const answers = [];
  panels.forEach((panel, i) => {
    if (i === panels.length - 1) {
      return;
    }
    const answer = { title: panel.title, selections: [] };
    if (panel.options !== undefined && panel.options.length > 0) {
      panel.options.forEach((option) => {
        if (option.selected) {
          answer.selections.push(option.title);
        }
      });
      if (answer.selections.length === 0) {
        answer.selections = ['No selections'];
      }
    }
    answers.push(answer);
  });
  return answers;
};

const SummaryPanel = ({ courseId, course, panels, submitWizard, goToWizard, router, active }) => {
  useEffect(() => {
    const handleBeforeUnload = () => {
      window.onbeforeunload = window.onbeforeunloadcache;
    };

    return () => {
      window.onbeforeunload = handleBeforeUnload;
    };
  }, []);

  const submit = () => {
    submitWizard(courseId);
    router.navigate(`/courses/${courseId}/timeline`);
  };

  const rewind = (toIndex) => {
    goToWizard(toIndex);
    window.location.hash = `step${toIndex + 1}`; // Sync Step Changes
    document.title = document.title.replace(/\d+$/, toIndex + 1); // Sync Title
  };

  let answers = [];
  if (active) {
    answers = answersFromPanels(panels);
  }

  const rawOptions = answers.map((answer, i) => {
    let details;
    if (i === 0) {
      details = (
        <p key={'course_dates_summary'}>
          {I18n.t('timeline.course_start')} — {course.start} <br />
          {I18n.t('timeline.course_end')} — {course.end} <br />
          {I18n.t('courses.assignment_start')} — {course.timeline_start} <br />
          {I18n.t('courses.assignment_end')} — {course.timeline_end}
        </p>
      );
    } else {
      details = answer.selections.map((selection, j) => <p key={`detail${i}${j}`}>{selection}</p>);
    }

    return (
      <button key={`answer${i}`} className="wizard__option summary" onClick={() => rewind(i)}>
        <h3>{answer.title}</h3>
        {details}
        <p className="edit">Edit</p>
      </button>
    );
  });

  return (
    <Panel
      courseId={courseId}
      course={course}
      panels={panels}
      advance={submit}
      raw_options={rawOptions}
      button_text="Generate Timeline"
    />
  );
};

SummaryPanel.propTypes = {
  courseId: PropTypes.string,
  course: PropTypes.object.isRequired,
  panels: PropTypes.array.isRequired,
  submitWizard: PropTypes.func.isRequired,
  goToWizard: PropTypes.func.isRequired,
  router: PropTypes.object.isRequired,
  active: PropTypes.bool.isRequired,
};

export default withRouter(SummaryPanel);
