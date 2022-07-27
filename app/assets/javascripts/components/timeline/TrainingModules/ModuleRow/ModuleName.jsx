import React from 'react';
import PropTypes from 'prop-types';
import { toDate } from '~/app/assets/javascripts/utils/date_utils';
import { format } from 'date-fns';

export const ModuleName = ({ due_date, isExercise, name }) => {
  const date = due_date ? due_date.replace(/\//g, '-') : null;
  const dueDate = format(toDate(date), 'MMM do');
  return (
    <td className="block__training-modules-table__module-name">
      {name}
      {
        isExercise
          ? <small className="due-date">Due on {dueDate}</small>
          : null
      }
    </td>
  );
};

ModuleName.propTypes = {
  due_date: PropTypes.string.isRequired,
  isExercise: PropTypes.bool.isRequired,
  name: PropTypes.string.isRequired
};

export default ModuleName;
