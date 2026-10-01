import React from 'react';
import PropTypes from 'prop-types';
import { Link, useSearchParams } from 'react-router-dom';
import CellDetails, { StateBadge } from './CellDetails';
import ItemLinks from './ItemLinks';
import { FILTERS, filterLabel, matchesFilter, studentName } from './assignmentHelpers';

const DETAILS_HEADINGS = {
  training: 'training_status.completed_at',
  exercise: 'lti.assignment_view.article_work.header',
  peer_review: 'lti.assignment_view.peer_review.reviews',
};

// One row per student with their status and a compact view of their work.
// (The assigned article has its own panel and table: ArticlePanel.)
const StudentRoster = ({ item, students, cellsByUser, studentPath }) => (
  <table className="table table--hoverable">
    <thead>
      <tr>
        <th>{I18n.t('lti.assignment_view.roster.student')}</th>
        <th>{I18n.t('lti.assignment_view.roster.status')}</th>
        <th>{I18n.t(DETAILS_HEADINGS[item.kind])}</th>
      </tr>
    </thead>
    <tbody>
      {students.map((student) => {
        const cell = cellsByUser[student.id];
        return (
          <tr key={student.id}>
            <td>
              <Link to={studentPath(student)}>
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
);

StudentRoster.propTypes = {
  item: PropTypes.object.isRequired,
  students: PropTypes.array.isRequired,
  cellsByUser: PropTypes.object.isRequired,
  studentPath: PropTypes.func.isRequired,
};

// One assignment, every student: the contents of its row's drawer in the
// list. The status filter rides in the URL, so the grader steps through the
// same students the roster shows.
const AssignmentRoster = ({ item, students, cellsByUser, itemPath }) => {
  const [searchParams, setSearchParams] = useSearchParams();
  const filter = searchParams.get('filter') || 'all';
  const shown = students.filter(student => matchesFilter(cellsByUser[student.id], filter));
  const query = filter === 'all' ? '' : `?filter=${filter}`;

  const studentPath = student => `${itemPath}/${encodeURIComponent(student.username)}${query}`;

  const onFilterChange = (event) => {
    const params = new URLSearchParams(searchParams);
    if (event.target.value === 'all') {
      params.delete('filter');
    } else {
      params.set('filter', event.target.value);
    }
    setSearchParams(params, { replace: true });
  };

  return (
    <div className="assignments-tab__roster">
      <ItemLinks item={item} />
      <label className="assignments-tab__filter">
        {I18n.t('lti.assignment_view.roster.status')}{' '}
        <select value={filter} onChange={onFilterChange}>
          {FILTERS.map(option => (
            <option key={option} value={option}>{filterLabel(option)}</option>
          ))}
        </select>
      </label>
      <StudentRoster item={item} students={shown} cellsByUser={cellsByUser} studentPath={studentPath} />
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
