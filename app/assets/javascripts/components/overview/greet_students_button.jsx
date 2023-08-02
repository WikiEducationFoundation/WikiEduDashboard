import React from 'react';
import PropTypes from 'prop-types';

const GreetStudentsButton = ({ greetStudents, current_user, course }) => {
  // Render nothing if user isn't an admin, or it's not the Wiki Ed Dashboard, or not a student course
  if (!current_user.admin || !Features.wikiEd || course.type !== 'ClassroomProgramCourse') {
    return <div />;
  }

  return (
    <div key="greet_students"><button onClick={() => greetStudents(course.id)} className="button">Greet students</button></div>
  );
};

GreetStudentsButton.propTypes = {
  course: PropTypes.object,
  current_user: PropTypes.object,
  greetStudents: PropTypes.func.isRequired
};

export default GreetStudentsButton;
