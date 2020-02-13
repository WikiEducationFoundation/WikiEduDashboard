import React from 'react';
import PropTypes from 'prop-types';

export const PeerReviewLink = ({ assignment, user }) => {
  const { sandboxUrl } = assignment;
  const { username } = user;
  let peerReviewUrl = `${sandboxUrl}/${username}_Peer_Review`;
  peerReviewUrl += '?veaction=edit&preload=Template:Dashboard.wikiedu.org_peer_review';
  return <a href={peerReviewUrl} target="_blank">{I18n.t('assignments.peer_review_link')}</a>;
};

PeerReviewLink.propTypes = {
  assignment: PropTypes.object.isRequired,
  user: PropTypes.object.isRequired,
};

export default PeerReviewLink;
