import React from 'react';
import PropTypes from 'prop-types';
import withRouter from '../../../util/withRouter';
import { selectUserByUsernameParam } from '@components/util/helpers';
import { onEnterOrSpace } from '../../../../utils/keyboard_handlers';

export const StudentSelection = ({ articlesUrl, router, selectStudent, students }) => {
  const selected = selectUserByUsernameParam(students, router.params.username);
  const lis = students.map((student) => {
    const handleSelect = () => {
      selectStudent(student);
      router.navigate(`${articlesUrl}/${encodeURIComponent(student.username)}`);
    };
    return (
      /* role="button" + tabIndex + onKeyDown make this li keyboard-accessible.
         The rule against giving <li> an interactive role is overly strict
         here; the alternative (wrapping the children in a <button>) breaks
         existing .student CSS that targets the li. */
      // eslint-disable-next-line jsx-a11y/no-noninteractive-element-to-interactive-role
      <li role="button" tabIndex={0} key={student.id}
        aria-pressed={selected && selected.id === student.id}
        className={`student ${selected && selected.id === student.id ? 'selected' : ''}`}
        onClick={handleSelect}
        onKeyDown={onEnterOrSpace(handleSelect)}
      >
        {
          student.real_name
          && <p className="real-name">{student.real_name}</p>
        }
        <p>{student.username}</p>
      </li>
    );
  });

  return <ul>{ lis }</ul>;
};

StudentSelection.propTypes = {
  students: PropTypes.array.isRequired
};

export default withRouter(StudentSelection);
