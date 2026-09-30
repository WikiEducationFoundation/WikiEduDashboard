import React from 'react';
import PropTypes from 'prop-types';
import { Link, useSearchParams } from 'react-router-dom';
import CellDetails, { StateBadge } from './CellDetails';
import { FILTERS, filterLabel, matchesFilter, studentName } from './assignmentHelpers';

const DETAILS_HEADINGS = {
  training: 'training_status.completed_at',
  exercise: 'lti.assignment_view.article_work.header',
  article: 'lti.assignment_view.article_work.header',
  peer_review: 'lti.assignment_view.peer_review.reviews',
};

// One assignment, every student. The status filter rides in the URL, so the
// grader steps through the same students the roster shows.
const AssignmentRoster = ({ item, students, cellsByUser, itemPath }) => {
  const [searchParams, setSearchParams] = useSearchParams();
  const filter = searchParams.get('filter') || 'all';
  const shown = students.filter(student => matchesFilter(cellsByUser[student.id], filter));
  const query = filter === 'all' ? '' : `?filter=${filter}`;

  const onFilterChange = (event) => {
    const value = event.target.value;
    setSearchParams(value === 'all' ? {} : { filter: value });
  };

  return (
    <div className="assignments-tab__roster">
      <label className="assignments-tab__filter">
        {I18n.t('lti.assignment_view.roster.status')}{' '}
        <select value={filter} onChange={onFilterChange}>
          {FILTERS.map(option => (
            <option key={option} value={option}>{filterLabel(option)}</option>
          ))}
        </select>
      </label>
      <table className="table table--hoverable">
        <thead>
          <tr>
            <th>{I18n.t('lti.assignment_view.roster.student')}</th>
            <th>{I18n.t('lti.assignment_view.roster.status')}</th>
            <th>{I18n.t(DETAILS_HEADINGS[item.kind])}</th>
          </tr>
        </thead>
        <tbody>
          {shown.map((student) => {
            const cell = cellsByUser[student.id];
            return (
              <tr key={student.id}>
                <td>
                  <Link to={`${itemPath}/${encodeURIComponent(student.username)}${query}`}>
                    {studentName(student)}
                  </Link>
                </td>
                <td><StateBadge cell={cell} /></td>
                <td><CellDetails cell={cell} item={item} compact /></td>
              </tr>
            );
          })}
        </tbody>
      </table>
    </div>
  );
};

AssignmentRoster.propTypes = {
  item: PropTypes.object.isRequired,
  students: PropTypes.array.isRequired,
  cellsByUser: PropTypes.object.isRequired,
  itemPath: PropTypes.string.isRequired,
};

export default AssignmentRoster;
