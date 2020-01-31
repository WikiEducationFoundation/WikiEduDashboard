import React from 'react';

export const NoAssignments = () => {
  return (
    <section className="no-assignments">
      <p>{I18n.t('instructor_view.exercises_and_trainings') }</p>
    </section>
  );
};

export default NoAssignments;
