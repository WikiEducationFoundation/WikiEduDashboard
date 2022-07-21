import React from 'react';
import PropTypes from 'prop-types';
import moment from 'moment';
import { formatWithTime } from '~/app/assets/javascripts/utils/date_utils';
// Helper Functions
import { isTrainingDue, orderByDueDate } from '@components/students/utils/trainingHelperFunctions';

export const TrainingModuleRows = ({ trainings }) => {
  trainings.sort(orderByDueDate);
  return trainings.map((trainingModule) => {
    const momentDueDate = moment(trainingModule.due_date);
    const dueDate = momentDueDate.format('MMM Do, YYYY');
    const overdue = trainingModule.overdue || momentDueDate.endOf('day').isBefore(trainingModule.completion_date);
    let moduleStatus;
    if (trainingModule.completion_date) {
      let completionTime = '';
      if (trainingModule.completion_time <= 60 * 60) {
        completionTime = `${I18n.t('training_status.completion_time')}: ${moment.utc(trainingModule.completion_time * 1000).format(`mm [${I18n.t('users.training_module_time.minutes')}] ss [${I18n.t('users.training_module_time.seconds')}]`)}`;
      }
      moduleStatus = (
        <>
          <span className="completed">
            {I18n.t('training_status.completed_at')}: {formatWithTime(trainingModule.completion_date)}
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
      <tr className={trainingModule.due_date && isTrainingDue(trainingModule.due_date) ? 'student-training-module due-training' : 'student-training-module'} key={trainingModule.id}>
        <td>{trainingModule.module_name} <small>Due by { dueDate }</small></td>
        <td>
          { moduleStatus }
        </td>
      </tr>
    );
  });
};

TrainingModuleRows.propTypes = {
  trainings: PropTypes.arrayOf(
    PropTypes.shape({
      completion_date: PropTypes.string,
      id: PropTypes.number.isRequired,
      module_name: PropTypes.string.isRequired,
      status: PropTypes.string
    }).isRequired
  ).isRequired
};

export default TrainingModuleRows;
