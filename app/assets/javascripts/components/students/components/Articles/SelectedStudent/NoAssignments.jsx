import React from 'react';

export const NoAssignments = () => {
  return (
    <div className="list__wrapper">
      <h4 className="assignments-list-title">
        {I18n.t('articles.assigned')}
      </h4>
      <section className="no-assignments">
        <p>{ I18n.t('instructor_view.no_assignments') }</p>
      </section>
    </div>
  );
};

export default NoAssignments;
