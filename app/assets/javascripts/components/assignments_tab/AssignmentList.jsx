import React from 'react';
import PropTypes from 'prop-types';
import { Link } from 'react-router-dom';
import { formatDate, itemTitle, kindLabel, stateLabel } from './assignmentHelpers';

// Every tracked assignment, in timeline order, with how many students are
// where on it.
const AssignmentList = ({ data, tabPath }) => {
  const summaryByKey = Object.fromEntries(data.summary.map(row => [row.key, row]));
  return (
    <table className="table table--hoverable assignments-tab__list">
      <thead>
        <tr>
          <th>{I18n.t('timeline.block_assignment')}</th>
          <th>{I18n.t('lti.assignment_view.trainings.due_date')}</th>
          <th>{stateLabel('complete')}</th>
          <th>{stateLabel('in_progress')}</th>
          <th>{stateLabel('not_started')}</th>
          <th>{I18n.t('assignments_tab.overdue')}</th>
        </tr>
      </thead>
      <tbody>
        {data.items.map((item) => {
          const summary = summaryByKey[item.key];
          return (
            <tr key={item.key}>
              <td>
                <Link to={`${tabPath}/${item.key}`}>{itemTitle(item)}</Link>
                <span className="assignments-tab__kind">{kindLabel(item)}</span>
              </td>
              <td>{formatDate(item.due_date)}</td>
              <td>{summary.complete}</td>
              <td>{summary.in_progress}</td>
              <td>{summary.not_started}</td>
              <td className={summary.overdue ? 'assignments-tab__overdue-count' : ''}>
                {summary.overdue || null}
              </td>
            </tr>
          );
        })}
      </tbody>
    </table>
  );
};

AssignmentList.propTypes = {
  data: PropTypes.shape({ items: PropTypes.array, summary: PropTypes.array }).isRequired,
  tabPath: PropTypes.string.isRequired,
};

export default AssignmentList;
