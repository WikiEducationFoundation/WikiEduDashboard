import React from 'react';
import PropTypes from 'prop-types';
import { Link } from 'react-router-dom';
import TrainingStatus from '@components/students/shared/StudentList/StudentDrawer/TrainingStatus/TrainingStatus.jsx';

const UserTrainingStatus = ({ trainingModules, username }) => {
  if (!trainingModules.length) { return null; }

  return (
    <div id="training-status">
      {username && (
        <div className="user-articles__navigation">
          <Link to={`/users/${encodeURIComponent(username)}`} className="button ghost small">
            ← {I18n.t('users.back_to_profile')}
          </Link>
        </div>
      )}
      <h3>{I18n.t('users.user_training_status')}</h3>
      <TrainingStatus exercises={{}} trainingModules={trainingModules} />
    </div>
  );
};

UserTrainingStatus.propTypes = {
  trainingModules: PropTypes.array.isRequired,
  username: PropTypes.string
};

export default UserTrainingStatus;
