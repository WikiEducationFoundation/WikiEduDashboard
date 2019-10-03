import React from 'react';
import PropTypes from 'prop-types';

// components
import AssignedToLink from './AssignedToLink';

export const ReviewerLink = ({ reviewers }) => {
  return <AssignedToLink members={reviewers} name="reviewers" />;
};

ReviewerLink.propTypes = {
  // props
  reviewers: PropTypes.arrayOf(
    PropTypes.string
  ),
};

export default ReviewerLink;
