import React from 'react';

export const NoAssignments = () => {
  return (
    <section className="no-assignments">
      <p>{ I18n.t('instructor_view.no_assignments') }</p>
    </section>
  );
};

export default NoAssignments;
