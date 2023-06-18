import React from 'react';
import PropTypes from 'prop-types';

// Components
import List from '@components/common/list.jsx';
import StudentExerciseRow from './StudentExerciseRow.jsx';
import StudentDrawer from '@components/students/shared/StudentList/StudentDrawer/StudentDrawer.jsx';

// Libraries
import CourseUtils from '~/app/assets/javascripts/utils/course_utils.js';
import { toDate } from '../../../../../../utils/date_utils';
import { addDays, isAfter } from 'date-fns';

// Helper Functions
const showRecent = (course) => {
  // If the last update was not more than 7 days ago, show the 'recent edits'
  // count. Otherwise, it's out of date because the course is no longer being
  // updated.
  const lastUpdate = course.updates.last_update;
  if (!lastUpdate) return false;
  return isAfter(addDays(toDate(lastUpdate.end_time), 7), new Date());
};

export const StudentExerciseList = (props) => {
  const {
    assignments, course, current_user, editAssignments, exerciseView, openKey, selected,
    sort, trainingStatus, wikidataLabels, sortUsers, userRevisions = {}
  } = props;

  const row = (
    <StudentExerciseRow
      assignments={assignments}
      course={course}
      current_user={current_user}
      editAssignments={editAssignments}
      key={selected.id}
      openKey={openKey}
      showRecent={showRecent(course)}
      student={selected}
      wikidataLabels={wikidataLabels}
    />
  );

  const drawer = (
    <StudentDrawer
      student={selected}
      course={course}
      exerciseView={exerciseView}
      key={`drawer_${selected.id}`}
      isOpen={openKey === `drawer_${selected.id}`}
      revisions={userRevisions[selected.id]}
      trainingModules={trainingStatus[selected.id]}
      wikidataLabels={wikidataLabels}
    />
  );

  const elements = [row, drawer];
  const keys = {
    course_exercise_progress_completed_count: {
      label: 'Exercises',
      desktop_only: false,
      sortable: true,
    },
    course_training_progress_completed_count: {
      label: 'Training Modules',
      desktop_only: false,
      sortable: true,
    },
  };

  if (!showRecent(course)) delete keys.recent_revisions;
  if (sort.key && keys[sort.key]) keys[sort.key].order = (sort.sortKey) ? 'asc' : 'desc';

  return (
    <div className="list__wrapper">
      <h4 className="assignments-list-title">
        {I18n.t('users.exercises_and_trainings')}
      </h4>
      <List
        elements={elements}
        className="table--expandable table--hoverable"
        keys={keys}
        table_key="users"
        none_message={CourseUtils.i18n('students_none', course.string_prefix)}
        sortBy={sortUsers}
        stickyHeader={false}
        sortable={true}
      />
    </div>
  );
};

StudentExerciseList.propTypes = {
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
  selected: PropTypes.object.isRequired,
  sortUsers: PropTypes.func,
  wikidataLabels: PropTypes.object,
};

export default StudentExerciseList;
