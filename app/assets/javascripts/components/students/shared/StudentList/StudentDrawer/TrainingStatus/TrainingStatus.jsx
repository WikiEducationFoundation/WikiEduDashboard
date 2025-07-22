import React from 'react';
import PropTypes from 'prop-types';

// Components
import TrainingModuleRows from './TrainingModuleRows';
import ExerciseRows from './ExerciseRows';

import {
  TRAINING_MODULE_KIND
} from '~/app/assets/javascripts/constants';
import { useSelector } from 'react-redux';

const TrainingStatus = ({ trainingModules }) => {
  const exercises = useSelector(state => state.exercises);
  if (!trainingModules.length) return <div />;

  const exerciseTable = !!exercises.count && (
    <table className="table">
      <thead>
        <tr>
          <th>Exercise Name</th>
          <th>Exercise Status</th>
        </tr>
      </thead>
      <tbody>
        <ExerciseRows exercises={exercises} />
      </tbody>
    </table>
  );

  const trainings = trainingModules.filter(({ kind }) => kind === TRAINING_MODULE_KIND);

  const trainingModuleTable = !!trainings.length && (
    <table className="table">
      <thead>
        <tr>
          <th>{I18n.t('users.training_module_name')}</th>
          <th>{I18n.t('users.training_module_status')}</th>
        </tr>
      </thead>
      <tbody>
        <TrainingModuleRows trainings={trainings} />
      </tbody>
    </table>
  );

  return (
    <>
      {exerciseTable}
      {trainingModuleTable}
    </>
  );
};

TrainingStatus.propTypes = {
  trainingModules: PropTypes.array
};

export default TrainingStatus;
