import React from 'react';
import PropTypes from 'prop-types';

import AssignmentLinks from '@components/common/AssignmentLinks/AssignmentLinks.jsx';

export const Links = ({ articleTitle, assignment, courseType, current_user }) => {
  return (
    <section className="header">
      <section className="title">
        <h4>{articleTitle}</h4>
      </section>
      <section className="editors">
        {AssignmentLinks({ articleTitle, assignment, courseType, current_user })}
      </section>
    </section>
  );
};

Links.propTypes = {
  // props
  articleTitle: PropTypes.string.isRequired,
  assignment: PropTypes.object.isRequired,
  courseType: PropTypes.string.isRequired,
  current_user: PropTypes.object.isRequired,
};

export default Links;
