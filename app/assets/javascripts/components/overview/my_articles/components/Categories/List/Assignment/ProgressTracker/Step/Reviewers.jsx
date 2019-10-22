import React from 'react';
import PropTypes from 'prop-types';

// components
export const Reviewers = ({ assignment = {} }) => {
  const { reviewers, sandboxUrl } = assignment;
  if (!reviewers) return null;

  const label = <span key="label">{I18n.t('assignments.reviewers')}: </span>;
  const links = reviewers.map((username, index, collection) => {
    return (
      <span key={username}>
        <a href={`${sandboxUrl}/Peer_Review_${username}`} target="_blank">
          {`${username}'s Review`}
        </a>
        {index < collection.length - 1 ? ', ' : null}
      </span>
    );
  });

  return (
    <section className="step-members">
      { [label].concat(links) }
    </section>
  );
};

Reviewers.propTypes = {
  // props
  assignment: PropTypes.shape({
    reviewers: PropTypes.array
  })
};

export default Reviewers;
