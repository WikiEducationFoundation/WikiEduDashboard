import React from 'react';
import PropTypes from 'prop-types';
import withRouter from '../../../util/withRouter';
import { selectUserByUsernameParam } from '@components/util/helpers';

export const StudentSelection = ({ articlesUrl, router, students }) => {
  const selected = selectUserByUsernameParam(students, router.params.username);
  const lis = students.map(student => (
    <li
      key={student.id}
      className={`student ${selected && selected.id === student.id ? 'selected' : ''}`}
      onClick={() => {
        router.navigate(`${articlesUrl}/${encodeURIComponent(student.username)}`);
      }}
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
