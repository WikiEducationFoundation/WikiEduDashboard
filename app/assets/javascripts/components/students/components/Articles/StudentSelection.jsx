import React from 'react';
import PropTypes from 'prop-types';
import { withRouter } from 'react-router';

export const StudentSelection = ({ articlesUrl, history, match, students }) => {
  const selected = students.find(({ username }) => username === match.params.username);
  const lis = students.map(student => (
    <li
      key={student.id}
      className={`student ${selected && selected.id === student.id ? 'selected' : ''}`}
      onClick={() => history.push(`${articlesUrl}/${student.username}`)}
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

export default withRouter(StudentSelection);
