import React from 'react';
import PropTypes from 'prop-types';

export const NoAssignments = () => {
  return (
    <section className="no-assignments">
      <p>This student currently has no assigned articles. You can assign an article by using the buttons above.</p>
    </section>
  );
};

NoAssignments.propTypes = {

};

export default NoAssignments;
