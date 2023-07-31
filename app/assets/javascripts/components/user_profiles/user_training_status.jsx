import React from 'react';
import PropTypes from 'prop-types';
import TrainingStatus from '@components/students/shared/StudentList/StudentDrawer/TrainingStatus/TrainingStatus.jsx';

const UserTrainingStatus = ({ trainingModules }) => {
  let status;
  if (trainingModules.length > 0) {
    status = <TrainingStatus exercises={{}} trainingModules={trainingModules} />;
  } else {
    status = <span>{I18n.t('users.user_no_training_status')}</span>;
  }
  return (
    <div id="training-status">
      <h3>Training Status</h3>
      {status}
    </div>
  );
};

UserTrainingStatus.propTypes = {
  trainingModules: PropTypes.array.isRequired
};

export default UserTrainingStatus;
