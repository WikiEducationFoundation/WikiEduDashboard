import React from 'react';
import PropTypes from 'prop-types';

const TrainingStatus = ({ trainingModules }) => {
  if (!trainingModules.length) {
    return <div />;
  }
  const moduleRows = trainingModules.map((trainingModule) => {
    let moduleStatus;
    if (trainingModule.completion_date) {
      moduleStatus = (
        <span className="completed">
          Completed at {moment(trainingModule.completion_date).format('YYYY-MM-DD   h:mm A')}
        </span>
      );
    } else {
      moduleStatus = (
        <span className="overdue">
          {trainingModule.status}
        </span>
      );
    }
    return (
      <tr className="student-training-module" key={trainingModule.id}>
        <td>{trainingModule.module_name}</td>
        <td>{moduleStatus}</td>
      </tr>
    );
  });

  return (
    <table className="table">
      <thead>
        <tr>
          <th>{I18n.t('users.training_module_name')}</th>
          <th>{I18n.t('users.training_module_status')}</th>
        </tr>
      </thead>
      <tbody>
        {moduleRows}
      </tbody>
    </table>
  );
};

TrainingStatus.propTypes = {
  trainingModules: PropTypes.array
};

export default TrainingStatus;
