import React from 'react';
import PropTypes from 'prop-types';
import _ from 'lodash';
import moment from 'moment';

// Components
import List from '@components/common/list.jsx';
import StudentExerciseRow from './StudentExerciseRow.jsx';
import StudentDrawer from '@components/students/shared/StudentList/StudentDrawer/StudentDrawer.jsx';

// Libraries
import CourseUtils from '~/app/assets/javascripts/utils/course_utils.js';

// Helper Functions
const showRecent = (course) => {
  // If the last update was not more than 7 days ago, show the 'recent edits'
  // count. Otherwise, it's out of date because the course is no longer being
  // updated.
  const lastUpdate = course.updates.last_update;
  if (!lastUpdate) return false;
  return moment.utc(lastUpdate.end_time).add(7, 'days').isAfter(moment());
};

export const StudentList = (props) => {
  const {
    assignments, course, current_user, editAssignments, exerciseView, openKey, sort, students,
    toggleUI, trainingStatus, wikidataLabels, sortUsers, userRevisions = {}
  } = props;

  const rows = students.map(student => (
    <StudentExerciseRow
      assignments={assignments}
      course={course}
      current_user={current_user}
      editAssignments={editAssignments}
      key={student.id}
      openKey={openKey}
      showRecent={showRecent(course)}
      student={student}
      toggleUI={toggleUI}
      wikidataLabels={wikidataLabels}
    />
  ));

  const drawers = students.map(student => (
    <StudentDrawer
      student={student}
      course={course}
      exerciseView={exerciseView}
      key={`drawer_${student.id}`}
      isOpen={openKey === `drawer_${student.id}`}
      revisions={userRevisions[student.id]}
      trainingModules={trainingStatus[student.id]}
      wikidataLabels={wikidataLabels}
    />
  ));

  const elements = _.flatten(_.zip(rows, drawers));
  const keys = {
    username: {
      label: I18n.t('users.name'),
      desktop_only: false,
      sortable: true,
    },
    exercises: {
      label: 'Exercises',
      desktop_only: false,
      sortable: true,
    },
    training_modules: {
      label: 'Training Modules',
      desktop_only: false,
      sortable: true,
    },
  };

  if (!showRecent(course)) delete keys.recent_revisions;
  if (sort.key && keys[sort.key]) keys[sort.key].order = (sort.sortKey) ? 'asc' : 'desc';

  return (
    <List
      elements={elements}
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
  openKey: PropTypes.string,
  sort: PropTypes.shape({
    key: PropTypes.string,
    sortKey: PropTypes.string
  }).isRequired,
  toggleUI: PropTypes.func,
  sortUsers: PropTypes.func,
  wikidataLabels: PropTypes.object,
};

export default StudentList;
