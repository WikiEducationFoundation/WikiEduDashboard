import React from 'react';
import PropTypes from 'prop-types';

const STATUSES = {
  not_yet_started: 'Getting Started',

  // assignments
  in_progress: 'Working in Sandbox',
  ready_for_review: 'Expanding Draft',
  ready_for_mainspace: 'Moving Work to Mainspace',
  assignment_completed: 'Assignment Marked Complete',

  // reviewing
  // not_yet_started: 'Reading Article',
  peer_review_started: 'Providing Feedback',
  peer_review_completed: ''
};

export const CurrentStatus = ({ current, statuses }) => (
  <>
    <span>{ statuses.indexOf(current) + 1 }/{ statuses.length }. </span>
    { STATUSES[current] }
  </>
);

CurrentStatus.propTypes = {
  current: PropTypes.string.isRequired,
  statuses: PropTypes.arrayOf(PropTypes.string).isRequired
};

export default CurrentStatus;
