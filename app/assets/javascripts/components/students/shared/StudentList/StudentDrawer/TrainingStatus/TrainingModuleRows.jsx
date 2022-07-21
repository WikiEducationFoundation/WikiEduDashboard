import React from 'react';
import PropTypes from 'prop-types';
import { formatWithTime, toDate } from '../../../../../../utils/date_utils';
// Helper Functions
import { isTrainingDue, orderByDueDate } from '@components/students/utils/trainingHelperFunctions';
import { endOfDay, format, isBefore, intervalToDuration } from 'date-fns';

export const TrainingModuleRows = ({ trainings }) => {
  trainings.sort(orderByDueDate);
  return trainings.map((trainingModule) => {
    const dueDate = toDate(trainingModule.due_date);
    const dueDateFormatted = format(dueDate, 'MMM do, yyyy');
    const overdue = trainingModule.overdue || isBefore(
      endOfDay(dueDate),
      toDate(trainingModule.completion_date)
    );
    let moduleStatus;
    if (trainingModule.completion_date) {
      let completionTime = '';
      if (trainingModule.completion_time <= 60 * 60) {
        const completion_time_duration = intervalToDuration({ start: 0, end: trainingModule.completion_time * 1000 });
        completionTime = `${I18n.t('training_status.completion_time')}: ${completion_time_duration.minutes} ${I18n.t('users.training_module_time.minutes')} ${completion_time_duration.seconds} ${I18n.t('users.training_module_time.seconds')}`;
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
        <td>{trainingModule.module_name} <small>Due by { dueDateFormatted }</small></td>
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
