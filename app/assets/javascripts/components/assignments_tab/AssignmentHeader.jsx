import React from 'react';
import PropTypes from 'prop-types';
import { Link } from 'react-router-dom';
import { formatDate, itemTitle, kindLabel } from './assignmentHelpers';

// The assignment a roster or grader is about: what it is, when it's due, and
// where it's done, with the way back to the full list.
const AssignmentHeader = ({ item, tabPath }) => (
  <div className="assignments-tab__header">
    <p><Link to={tabPath}>← {I18n.t('assignments_tab.label')}</Link></p>
    <h3>{itemTitle(item)}</h3>
    <p className="assignments-tab__meta">
      <span className="assignments-tab__kind">{kindLabel(item)}</span>
      {item.due_date && (
        <span> · {I18n.t('training_status.due', { due_date: formatDate(item.due_date) })}</span>
      )}
      {item.training_url && (
        <span>
          {' · '}
          <a href={item.training_url} target="_blank" rel="noopener noreferrer">
            {item.kind === 'exercise'
              ? I18n.t('lti.assignment_view.student.launch_instructions')
              : I18n.t('training_status.view')}
          </a>
        </span>
      )}
      {item.exercise_url && (
        <span>
          {' · '}
          <a href={item.exercise_url} target="_blank" rel="noopener noreferrer">
            {I18n.t('lti.assignment_view.student.open_exercise')}
          </a>
        </span>
      )}
    </p>
  </div>
);

AssignmentHeader.propTypes = {
  item: PropTypes.object.isRequired,
  tabPath: PropTypes.string.isRequired,
};

export default AssignmentHeader;
