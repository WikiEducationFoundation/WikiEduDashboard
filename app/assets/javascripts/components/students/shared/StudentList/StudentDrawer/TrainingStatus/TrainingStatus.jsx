import React from 'react';
import PropTypes from 'prop-types';

// Components
import TrainingModuleRows from './TrainingModuleRows';
import ExerciseRows from './ExerciseRows';

const TrainingStatus = ({ exercises, trainingModules }) => {
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

  const trainingModuleTable = (
    <table className="table">
      <thead>
        <tr>
          <th>{I18n.t('users.training_module_name')}</th>
          <th>{I18n.t('users.training_module_status')}</th>
        </tr>
      </thead>
      <tbody>
        <TrainingModuleRows trainingModules={trainingModules} />
      </tbody>
    </table>
  );

  return (
    <>
      { exerciseTable }
      { trainingModuleTable }
    </>
  );
};

TrainingStatus.propTypes = {
  exercises: PropTypes.object,
  trainingModules: PropTypes.array
};

export default TrainingStatus;
