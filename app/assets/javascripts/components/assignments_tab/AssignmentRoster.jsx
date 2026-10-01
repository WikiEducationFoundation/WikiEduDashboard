import React from 'react';
import PropTypes from 'prop-types';
import { Link, useSearchParams } from 'react-router-dom';
import CellDetails, { StateBadge } from './CellDetails';
import ItemLinks from './ItemLinks';
import { StudentHeaders, hasRealNames, useStudentSort } from './StudentSort';
import { FILTERS, filterLabel, listQuery, matchesFilter, sortStudents } from './assignmentHelpers';

const DETAILS_HEADINGS = {
  training: 'training_status.completed_at',
  exercise: 'lti.assignment_view.article_work.header',
  peer_review: 'lti.assignment_view.peer_review.reviews',
};

// One row per student with their status and a compact view of their work,
// sortable by any of the student columns. (The assigned article has its own
// panel and table: ArticlePanel.)
const StudentRoster = ({ item, students, cellsByUser, studentPath, showNames }) => {
  const { sort, sortBy } = useStudentSort();
  return (
    <table className="table table--hoverable">
      <thead>
        <tr>
          <StudentHeaders showNames={showNames} sort={sort} sortBy={sortBy} />
          <th>{I18n.t(DETAILS_HEADINGS[item.kind])}</th>
        </tr>
      </thead>
      <tbody>
        {sortStudents(students, cellsByUser, sort).map((student) => {
          const cell = cellsByUser[student.id];
          return (
            <tr key={student.id}>
              {showNames && <td>{student.real_name}</td>}
              <td><Link to={studentPath(student)}>{student.username}</Link></td>
              <td><StateBadge cell={cell} /></td>
              <td><CellDetails cell={cell} item={item} compact /></td>
            </tr>
          );
        })}
      </tbody>
    </table>
  );
};

StudentRoster.propTypes = {
  item: PropTypes.object.isRequired,
  students: PropTypes.array.isRequired,
  cellsByUser: PropTypes.object.isRequired,
  studentPath: PropTypes.func.isRequired,
  showNames: PropTypes.bool.isRequired,
};

// One assignment, every student: the contents of its row's drawer in the
// list. The status filter and sort ride in the URL, so the grader steps
// through the same students the roster shows, in the same order.
const AssignmentRoster = ({ item, students, cellsByUser, itemPath }) => {
  const [searchParams, setSearchParams] = useSearchParams();
  const filter = searchParams.get('filter') || 'all';
  const shown = students.filter(student => matchesFilter(cellsByUser[student.id], filter));
  const studentPath = student => `${itemPath}/${encodeURIComponent(student.username)}${listQuery(searchParams)}`;

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
      <StudentRoster
        item={item} students={shown} cellsByUser={cellsByUser} studentPath={studentPath}
        showNames={hasRealNames(students)}
      />
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
