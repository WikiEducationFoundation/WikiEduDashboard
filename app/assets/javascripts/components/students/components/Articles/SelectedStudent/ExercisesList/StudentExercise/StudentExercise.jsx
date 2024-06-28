import React, { useCallback } from 'react';

import { connect } from 'react-redux';
import PropTypes from 'prop-types';

import { setUploadFilters as setUploadFiltersAction } from '~/app/assets/javascripts/actions/uploads_actions';
import { fetchUserRevisions as fetchUserRevisionsAction } from '~/app/assets/javascripts/actions/user_revisions_actions';
import { fetchTrainingStatus as fetchTrainingStatusAction } from '~/app/assets/javascripts/actions/training_status_actions';

// Components
import ExerciseProgressDescription from './ExerciseProgressDescription.jsx';
import TrainingProgressDescription from './TrainingProgressDescription.jsx';

// Actions
import { fetchTrainingModuleExercisesByUser } from '~/app/assets/javascripts/actions/exercises_actions';

const Student = ({
  course,
  student,
  isOpen,
  toggleDrawer,
}) => {
  const handleSetUploadFilters = useCallback((selectedFilters) => {
    setUploadFiltersAction(selectedFilters);
  }, [setUploadFiltersAction]);

  const handleStop = (e) => {
    e.stopPropagation();
  };

  const openDrawer = useCallback(() => {
    if (!isOpen) {
      fetchUserRevisionsAction(course.id, student.id);
      fetchTrainingStatusAction(student.id, course.id);
      fetchTrainingModuleExercisesByUser(course.id, student.id);
    }
    toggleDrawer(`drawer_${student.id}`);
  }, [isOpen, course.id, student.id, fetchUserRevisionsAction, fetchTrainingStatusAction, toggleDrawer]);

  const className = `students-exercise students${isOpen ? ' open' : ''}`;

  // Example filters object
  const exampleFilters = { filterType: 'example' };

  return (
    <tr onClick={openDrawer} className={className}>
      <td className="desktop-only-tc">
        <ExerciseProgressDescription student={student} />
      </td>
      <td className="desktop-only-tc">
        <TrainingProgressDescription student={student} />
      </td>
      <td className="table-action-cell">
        <button className="icon icon-arrow-toggle table-expandable-indicator" onClick={handleStop} />
      </td>
      <td className="table-action-cell">
        <button onClick={() => handleSetUploadFilters(exampleFilters)}/>
      </td>
    </tr>
  );
};

Student.propTypes = {
  course: PropTypes.object.isRequired,
  student: PropTypes.object.isRequired,
  isOpen: PropTypes.bool,
  toggleDrawer: PropTypes.func,
  fetchUserRevisionsAction: PropTypes.func.isRequired,
  fetchTrainingStatusAction: PropTypes.func.isRequired,
  setUploadFiltersAction: PropTypes.func.isRequired
};

const mapDispatchToProps = {
  setUploadFiltersAction,
  fetchUserRevisionsAction,
  fetchTrainingStatusAction,
  fetchExercises: fetchTrainingModuleExercisesByUser
};

export default connect(null, mapDispatchToProps)(Student);
