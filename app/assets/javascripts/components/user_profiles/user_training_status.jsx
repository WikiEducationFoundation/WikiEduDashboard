import React from 'react';
import PropTypes from 'prop-types';
import createReactClass from 'create-react-class';
import TrainingStatus from '@components/students/shared/StudentList/StudentDrawer/TrainingStatus/TrainingStatus.jsx';

const UserTrainingStatus = createReactClass({
  propTypes: {
    trainingModules: PropTypes.array.isRequired
  },
  render() {
    let status;
    if (this.props.trainingModules.length > 0) {
      status = <TrainingStatus trainingModules={this.props.trainingModules} />;
    } else {
      status = <span>{I18n.t('users.user_no_training_status')}</span>;
    }
    return (
      <div id="training-status">
        <h3>Training Status</h3>
        {status}
      </div>
    );
  }
});

export default UserTrainingStatus;
