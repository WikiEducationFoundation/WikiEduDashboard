import React from 'react';
import PropTypes from 'prop-types';

// components
import ReviewerLink from '../../../../../../common/ReviewerLink';

export const Reviewers = ({ reviewers }) => {
  if (!reviewers) return null;

  return (
    <section className="step-members">
      <ReviewerLink reviewers={reviewers} />
    </section>
  );
};

Reviewers.propTypes = {
  // props
  reviewers: PropTypes.array
};

export default Reviewers;
