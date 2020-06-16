import React from 'react';
import PropTypes from 'prop-types';
import dayjs from 'dayjs';
import utc from 'dayjs/plugin/utc';

import {
  TRAINING_MODULE_KIND
} from '~/app/assets/javascripts/constants';

dayjs.extend(utc);

export const TrainingModuleRows = ({ trainingModules }) => {
  const trainings = trainingModules.filter(({ kind }) => kind === TRAINING_MODULE_KIND);
  return trainings.map((trainingModule) => {
    const dayjsDueDate = dayjs(trainingModule.due_date);
    const dueDate = dayjsDueDate.format('MMM Do, YYYY');
    const overdue = trainingModule.overdue || dayjsDueDate.isBefore(trainingModule.completion_date);

    let moduleStatus;
    if (trainingModule.completion_date) {
      let completionTime = '';
      if (trainingModule.completion_time <= 60 * 60) {
        completionTime = `${I18n.t('training_status.completion_time')}: ${dayjs.utc(trainingModule.completion_time * 1000).format(`mm [${I18n.t('users.training_module_time.minutes')}] ss [${I18n.t('users.training_module_time.seconds')}]`)}`;
      }
      moduleStatus = (
        <>
          <span className="completed">
            {I18n.t('training_status.completed_at')}: {dayjs(trainingModule.completion_date).format('YYYY-MM-DD   h:mm A')}
          </span>
          { overdue && <span> ({I18n.t('training_status.late')})</span> }
          <br/>
          <span className="completed">
            {completionTime}
          </span>
        </>
      );
    } else {
      moduleStatus = (
        <>
          <span className="overdue">
            {trainingModule.status}
          </span>
          {overdue && <span> ({I18n.t('training_status.late')})</span>}
        </>
      );
    }


    return (
      <tr className="student-training-module" key={trainingModule.id}>
        <td>{trainingModule.module_name} <small>Due by { dueDate }</small></td>
        <td>
          { moduleStatus }
        </td>
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
