import React from 'react';
import PropTypes from 'prop-types';

export const PeerReviewLink = ({ assignment, current_user }) => {
  const { sandboxUrl } = assignment;
  const { username } = current_user;
  let peerReviewUrl = `${sandboxUrl}/${username}_Peer_Review`;
  peerReviewUrl += '?veaction=edit&preload=Template:Dashboard.wikiedu.org_peer_review';
  return <a href={peerReviewUrl} target="_blank">{I18n.t('assignments.peer_review_link')}</a>;
};

PeerReviewLink.propTypes = {
  assignment: PropTypes.object.isRequired,
  current_user: PropTypes.object.isRequired,
};

export default PeerReviewLink;
