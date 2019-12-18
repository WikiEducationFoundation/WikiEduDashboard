import React from 'react';
import PropTypes from 'prop-types';

export const StudentSelection = ({ selected, selectStudent, students }) => {
  const lis = students.map(student => (
    <li
      key={student.id}
      className={`student ${selected && selected.id === student.id ? 'selected' : ''}`}
      onClick={() => selectStudent(student)}
    >
      {
        student.real_name
        && <p className="real-name">{student.real_name}</p>
      }
      <p>{student.username}</p>
    </li>
  ));

  return <ul>{ lis }</ul>;
};

StudentSelection.propTypes = {
  students: PropTypes.array.isRequired
};

export default StudentSelection;
