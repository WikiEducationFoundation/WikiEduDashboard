import React from 'react';
import PropTypes from 'prop-types';
import TrainingStatus from '@components/students/shared/StudentList/StudentDrawer/TrainingStatus/TrainingStatus.jsx';

const UserTrainingStatus = ({ trainingModules }) => {
  if (!trainingModules.length) { return null; }

  return (
    <div id="training-status">
      <h3>{I18n.t('users.user_training_status')}</h3>
      <TrainingStatus exercises={{}} trainingModules={trainingModules} />
    </div>
  );
};

UserTrainingStatus.propTypes = {
  trainingModules: PropTypes.array.isRequired
};

export default UserTrainingStatus;
