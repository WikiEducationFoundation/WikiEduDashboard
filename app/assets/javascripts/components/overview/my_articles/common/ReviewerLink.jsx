import React from 'react';

// components
import AssignedToLink from './AssignedToLink';

export default ({ reviewers }) => {
  return <AssignedToLink members={reviewers} name="reviewers" />;
};
