import React from 'react';
import PropTypes from 'prop-types';

// Components
import List from '@components/common/list.jsx';
import StudentRow from '@components/students/shared/StudentList/StudentRow.jsx';

// Libraries
import CourseUtils from '~/app/assets/javascripts/utils/course_utils.js';
import studentListKeys from './student_list_keys';

import { addDays, isAfter } from 'date-fns';
import { toDate } from '../../../../utils/date_utils';
import { useSelector } from 'react-redux';

// Helper Functions
const showRecent = (course) => {
  // If the last update was not more than 7 days ago, show the 'recent edits'
  // count. Otherwise, it's out of date because the course is no longer being
  // updated.
  const lastUpdate = course.updates.last_update;
  if (!lastUpdate) return false;
  return isAfter(addDays(toDate(lastUpdate.end_time), 7), new Date());
};

const StudentsPagination = ({ totalItems, itemsPerPage, currentPage, onPageChange, totalPages }) => {
  const pageNumbers = Array.from({ length: totalPages }, (_, i) => i + 1);
  return (
    <>
      <div className="pagination" style={{ margin: '5px 10px' }}>
        <a
          className={`previous_page ${currentPage === 1 ? 'disabled' : ''}`}
          onClick={(e) => {
            e.preventDefault();
            if (currentPage > 1) onPageChange(currentPage - 1);
          }}
          href="#"
        >
          {I18n.t('articles.previous')}
        </a>
        {
          pageNumbers.map(number => (
            <a
              key={number}
              className={currentPage === number ? 'current' : ''}
              onClick={(e) => {
                e.preventDefault();
                if (currentPage !== number) onPageChange(number);
              }}
              href="#"
              style={currentPage === number ? {
                cursor: 'default',
                backgroundColor: '#676eb4',
                color: '#fff',
                border: 'none'
              } : {}}
            >
              {number}
            </a>
          ))
        }
        <a
          className={`next_page ${currentPage === totalPages ? 'disabled' : ''}`}
          onClick={(e) => {
            e.preventDefault();
            if (currentPage < totalPages) onPageChange(currentPage + 1);
          }}
          href="#"
        >
          {I18n.t('articles.next')}
        </a>
      </div>
      <div className="page-entries-info" style={{ textAlign: 'center', color: '#666', fontSize: '14px', marginTop: '0' }}>
        {I18n.t('articles.page_info', {
          current: currentPage,
          total_pages: totalPages,
          count: itemsPerPage,
          total: totalItems
        })}
      </div>
    </>
  );
};

export const StudentList = ({ assignments, course, current_user, editAssignments, students, sortUsers = {} }) => {
  const sort = useSelector(state => state.users.sort);
  const [page, setPage] = React.useState(1);
  const perPage = 25;
  const paginatedStudents = students.slice((page - 1) * perPage, page * perPage);
  const totalPages = Math.ceil(students.length / perPage);
  const rows = paginatedStudents.map(student => (
    <StudentRow
      assignments={assignments}
      course={course}
      current_user={current_user}
      editAssignments={editAssignments}
      key={student.id}
      showRecent={showRecent(course)}
      student={student}
    />
  ));

  const keys = studentListKeys(course);
  if (!showRecent(course)) delete keys.recent_revisions;
  if (sort.key && keys[sort.key]) keys[sort.key].order = (sort.sortKey) ? 'asc' : 'desc';

  return (
    <>
      <List
        elements={rows}
        className="table--expandable table--hoverable"
        keys={keys}
        table_key="users"
        none_message={CourseUtils.i18n('students_none', course.string_prefix)}
        sortBy={sortUsers}
        stickyHeader={true}
        sortable={true}
      />

      <StudentsPagination
        totalItems={students.length}
        itemsPerPage={perPage}
        currentPage={page}
        onPageChange={setPage}
        totalPages={totalPages}
      />
    </>
  );
};

StudentList.propTypes = {
  assignments: PropTypes.array,
  course: PropTypes.shape({
    string_prefix: PropTypes.string.isRequired,
    updates: PropTypes.shape({
      last_update: PropTypes.shape({
        end_time: PropTypes.string
      })
    }).isRequired
  }).isRequired,
  current_user: PropTypes.object.isRequired,
  editAssignments: PropTypes.bool,
  sortUsers: PropTypes.func,
};

export default StudentList;
