import React from 'react';
import PropTypes from 'prop-types';
import { generatePath, withRouter } from 'react-router';

export const StudentSelection = ({ course, history, match, students }) => {
  const selected = students.find(({ username }) => username === match.params.username);
  const lis = students.map(student => (
    <li
      key={student.id}
      className={`student ${selected && selected.id === student.id ? 'selected' : ''}`}
      onClick={() => {
        const [course_school, course_title] = course.slug.split('/');
        const root = '/courses/:course_school/:course_title/students/articles';
        const path = generatePath(root, { course_school, course_title });
        history.push(`${path}/${student.username}`);
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
