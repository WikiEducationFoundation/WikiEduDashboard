import React from 'react';
import PropTypes from 'prop-types';
import { useSearchParams } from 'react-router-dom';
import { DEFAULT_SORT, parseSort } from './assignmentHelpers';

// A student list's sort, kept in the URL (?sort=<column>, "-<column>" for
// descending) so the grader steps through the students in the same order.
// Sorting by the sorted column again reverses it.
export const useStudentSort = () => {
  const [searchParams, setSearchParams] = useSearchParams();
  const sort = searchParams.get('sort') || DEFAULT_SORT;

  const sortBy = (column) => {
    const { key, descending } = parseSort(sort);
    const next = key === column && !descending ? `-${column}` : column;
    const params = new URLSearchParams(searchParams);
    if (next === DEFAULT_SORT) {
      params.delete('sort');
    } else {
      params.set('sort', next);
    }
    setSearchParams(params, { replace: true });
  };

  return { sort, sortBy };
};

// A column heading that sorts the list. The heading's button does the
// sorting, so it's reachable by keyboard; the sorted column carries aria-sort.
const SortableHeader = ({ column, label, sort, sortBy }) => {
  const { key, descending } = parseSort(sort);
  const active = key === column;
  let ariaSort;
  if (active) { ariaSort = descending ? 'descending' : 'ascending'; }
  const indicator = active ? `sortable-indicator-${descending ? 'desc' : 'asc'}` : '';
  return (
    <th aria-sort={ariaSort}>
      <button type="button" className="assignments-tab__sort" onClick={() => sortBy(column)}>
        {label}
        <span className={`assignments-tab__sort-indicator ${indicator}`} aria-hidden="true" />
      </button>
    </th>
  );
};

SortableHeader.propTypes = {
  column: PropTypes.string.isRequired,
  label: PropTypes.node.isRequired,
  sort: PropTypes.string.isRequired,
  sortBy: PropTypes.func.isRequired,
};

// Whether a list gets a Name column: only when the viewer may see real names
// and some student has one.
export const hasRealNames = students => students.some(student => student.real_name);

// The columns both student tables lead with, each sortable: real name (see
// hasRealNames), username and status.
export const StudentHeaders = ({ showNames, sort, sortBy }) => (
  <>
    {showNames && <SortableHeader column="name" label={I18n.t('users.name')} sort={sort} sortBy={sortBy} />}
    <SortableHeader
      column="username" label={I18n.t('lti.assignment_view.roster.username')} sort={sort} sortBy={sortBy}
    />
    <SortableHeader
      column="status" label={I18n.t('lti.assignment_view.roster.status')} sort={sort} sortBy={sortBy}
    />
  </>
);

StudentHeaders.propTypes = {
  showNames: PropTypes.bool.isRequired,
  sort: PropTypes.string.isRequired,
  sortBy: PropTypes.func.isRequired,
};
