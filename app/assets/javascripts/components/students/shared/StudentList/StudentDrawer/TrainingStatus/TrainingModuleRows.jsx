import React from 'react';
import PropTypes from 'prop-types';
import moment from 'moment';

export const TrainingModuleRows = ({ trainingModules }) => {
  return trainingModules.map((trainingModule) => {
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
};

TrainingModuleRows.propTypes = {
  trainingModules: PropTypes.arrayOf(
    PropTypes.shape({
      completion_date: PropTypes.string,
      id: PropTypes.number.isRequired,
      module_name: PropTypes.string.isRequired,
      status: PropTypes.string
    }).isRequired
  ).isRequired
};

export default TrainingModuleRows;
