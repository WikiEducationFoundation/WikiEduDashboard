import React from 'react';
import PropTypes from 'prop-types';
import { formatDate, kindLabel } from './assignmentHelpers';

// Where an assignment is done: the module's training page (an exercise's
// instructions) or in-app page. With `withSummary`, led by its kind and due
// date, for places that don't already show them (the grader's heading).
const ItemLinks = ({ item, withSummary = false }) => {
  const parts = [];
  if (withSummary) {
    // The assigned article's title already says what it is.
    if (item.kind !== 'article') {
      parts.push(<span key="kind" className="assignments-tab__kind">{kindLabel(item)}</span>);
    }
    if (item.due_date) {
      parts.push(
        <span key="due">{I18n.t('training_status.due', { due_date: formatDate(item.due_date) })}</span>
      );
    }
  }
  if (item.training_url) {
    parts.push(
      <a key="training" href={item.training_url} target="_blank" rel="noopener noreferrer">
        {item.kind === 'exercise'
          ? I18n.t('lti.assignment_view.student.launch_instructions')
          : I18n.t('assignments_tab.view_training')}
      </a>
    );
  }
  if (item.exercise_url) {
    parts.push(
      <a key="exercise" href={item.exercise_url} target="_blank" rel="noopener noreferrer">
        {I18n.t('lti.assignment_view.student.open_exercise')}
      </a>
    );
  }
  if (!parts.length) { return null; }
  return (
    <p className="assignments-tab__meta">
      {parts.flatMap((part, index) => (index ? [' · ', part] : [part]))}
    </p>
  );
};

ItemLinks.propTypes = { item: PropTypes.object.isRequired, withSummary: PropTypes.bool };

export default ItemLinks;
