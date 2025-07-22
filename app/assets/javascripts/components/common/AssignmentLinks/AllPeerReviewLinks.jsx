import React from 'react';
import PropTypes from 'prop-types';
import { connect } from 'react-redux';
import { getReviewAssignments } from '../../../selectors';

// Components
import Separator from '@components/overview/my_articles/common/Separator.jsx';

export const AllPeerReviewLinks = ({ assignment, reviewAssignments }) => {
  const title = <span key="title">Reviews: </span>;
  const reviewLinks = assignment.reviewers.map((reviewer) => {
    let linkClass = '';
    let mouseoverText;

    const reviewerAssignment = reviewAssignments.find((revAssignment) => {
      return (revAssignment.article_title === assignment.article_title)
        && (revAssignment.username === reviewer);
    });
    const reviewStatus = reviewerAssignment?.peer_review_sandbox_status;
    if (reviewStatus === 'does_not_exist') {
      linkClass += 'redlink';
      mouseoverText = I18n.t('assignments.sandbox_redlink_info');
    }
    const url = assignment.sandboxUrl || assignment.sandbox_url;
    const peerReviewUrl = `${url}/${reviewer}_Peer_Review`;
    return (
      <a key={`${reviewer}-review`} href={peerReviewUrl} className={linkClass} target="_blank" title={mouseoverText}>
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

const mapStateToProps = state => ({
  reviewAssignments: getReviewAssignments(state)
});

export default connect(mapStateToProps)(AllPeerReviewLinks);
