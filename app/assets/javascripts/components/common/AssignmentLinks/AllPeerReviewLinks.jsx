import React from 'react';
import PropTypes from 'prop-types';

// Components
import Separator from '@components/overview/my_articles/common/Separator.jsx';

export const AllPeerReviewLinks = ({ assignment }) => {
  const title = <span key="title">Reviews: </span>;
  const reviewLinks = assignment.reviewers.map((reviewer) => {
    const url = assignment.sandboxUrl || assignment.sandbox_url;
    const peerReviewUrl = `${url}/${reviewer}_Peer_Review`;
    return (
      <a key={`${reviewer}-review`} href={peerReviewUrl} target="_blank">
        {I18n.t('assignments.peer_review_link_personalized', { username: reviewer })}
      </a>
    );
  });

  const separatedLinks = reviewLinks.reduce((acc, element, i, collection) => {
    acc.push(element);
    const isLastOne = (collection.length - 1) === i;
    if (!isLastOne) acc.push(<Separator key={i} />);
    return acc;
  }, []);

  return [title].concat(separatedLinks);
};

AllPeerReviewLinks.propTypes = {
  assignment: PropTypes.shape({
    reviewers: PropTypes.arrayOf(
      PropTypes.string.isRequired
    ).isRequired
  }).isRequired
};

export default AllPeerReviewLinks;
