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

// Helper Functions
const showRecent = (course) => {
  // If the last update was not more than 7 days ago, show the 'recent edits'
  // count. Otherwise, it's out of date because the course is no longer being
  // updated.
  const lastUpdate = course.updates.last_update;
  if (!lastUpdate) return false;
  return isAfter(addDays(toDate(lastUpdate.end_time), 7), new Date());
};

export const StudentList = (props) => {
  const {
    assignments, course, current_user, editAssignments, sort, students,
    wikidataLabels, sortUsers = {}
  } = props;

  const rows = students.map(student => (
    <StudentRow
      assignments={assignments}
      course={course}
      current_user={current_user}
      editAssignments={editAssignments}
      key={student.id}
      showRecent={showRecent(course)}
      student={student}
      wikidataLabels={wikidataLabels}
    />
  ));

  const keys = studentListKeys(course);
  if (!showRecent(course)) delete keys.recent_revisions;
  if (sort.key && keys[sort.key]) keys[sort.key].order = (sort.sortKey) ? 'asc' : 'desc';

  return (
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
  );
};

StudentList.propTypes = {
  assignments: PropTypes.array,
  trainingStatus: PropTypes.object.isRequired,
  userRevisions: PropTypes.object,
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
  sort: PropTypes.shape({
    key: PropTypes.string,
    sortKey: PropTypes.string
  }).isRequired,
  sortUsers: PropTypes.func,
  wikidataLabels: PropTypes.object,
};

export default StudentList;
