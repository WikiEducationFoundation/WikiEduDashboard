import React from 'react';
import PropTypes from 'prop-types';

import AssignmentLinks from '@components/common/AssignmentLinks/AssignmentLinks.jsx';

export const MyArticlesAssignmentLinks = ({ articleTitle, assignment, courseType, current_user, course, project }) => {
  return (
    <section className="header">
      <section className="title">
        <h4>{articleTitle}</h4>
      </section>
      <section className="editors">
        <AssignmentLinks assignment={assignment} courseType={courseType} user={current_user} project={project} editMode={true} course={course}/>
      </section>
    </section>
  );
};

MyArticlesAssignmentLinks.propTypes = {
  // props
  articleTitle: PropTypes.string.isRequired,
  project: PropTypes.string.isRequired,
  assignment: PropTypes.object.isRequired,
  courseType: PropTypes.string.isRequired,
  current_user: PropTypes.object.isRequired,
};

export default MyArticlesAssignmentLinks;
