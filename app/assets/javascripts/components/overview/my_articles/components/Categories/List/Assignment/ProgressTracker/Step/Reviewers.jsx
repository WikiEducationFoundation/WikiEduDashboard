import React from 'react';

// components
import ReviewerLink from '../../../../../../common/ReviewerLink';

export default ({ reviewers }) => {
  if (!reviewers) return null;

  return (
    <section className="step-members">
      <ReviewerLink reviewers={reviewers} />
    </section>
  );
};
