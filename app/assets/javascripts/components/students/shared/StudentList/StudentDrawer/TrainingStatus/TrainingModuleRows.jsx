import React from 'react';
import PropTypes from 'prop-types';
import { formatDateWithTime, toDate } from '../../../../../../utils/date_utils';
// Helper Functions
import { isTrainingDue, orderByDueDate } from '@components/students/utils/trainingHelperFunctions';
import { endOfDay, format, isBefore, intervalToDuration, isValid } from 'date-fns';

export const TrainingModuleRows = ({ trainings }) => {
  trainings.sort(orderByDueDate);
  return trainings.map((trainingModule) => {
    // due_date is not defined for the user profile page. This prevents the error from toDate if due_date is not defined
    const dueDate = toDate(trainingModule.due_date, !trainingModule.due_date);
    const dueDateFormatted = format(dueDate, 'MMM do, yyyy');
    const overdue = trainingModule.overdue || isBefore(
      endOfDay(dueDate),
      toDate(trainingModule.completion_date)
    );
    let moduleStatus;
    if (trainingModule.completion_date) {
      // Only display completion times under 1 hour, since
      // after that it probably means it was completed in
      // multiple sessions and we can't tell how much time
      // was actually spent on it.
      let completionTime = '';
      if (trainingModule.completion_time <= 60 * 60) {
        const completion_time_duration = intervalToDuration({ start: 0, end: trainingModule.completion_time * 1000 });
        completionTime = `${I18n.t('training_status.completion_time')}: ${completion_time_duration.minutes} ${I18n.t('users.training_module_time.minutes')} ${completion_time_duration.seconds} ${I18n.t('users.training_module_time.seconds')}`;
      }
      moduleStatus = (
        <>
          <span className="completed">
            {I18n.t('training_status.completed_at')}: {formatDateWithTime(trainingModule.completion_date)}
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
        <td>{trainingModule.module_name}
          {/* Only display the date if it is valid. On the users page, we don't fetch the due date so this is expected */}
          {isValid(dueDateFormatted) && <small>Due by { dueDateFormatted }</small>}
        </td>
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
