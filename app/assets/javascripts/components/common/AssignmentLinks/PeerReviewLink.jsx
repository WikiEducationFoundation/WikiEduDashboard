import React from 'react';
import PropTypes from 'prop-types';

export const PeerReviewLink = ({ assignment, user }) => {
  const { sandboxUrl } = assignment;
  const { username } = user;
  const sandboxExists = assignment.peer_review_sandbox_status !== 'does_not_exist';
  let peerReviewUrl = `${sandboxUrl}/${username}_Peer_Review`;
  let linkClass = '';
  let mouseoverText;

  if (!sandboxExists) {
    peerReviewUrl += '?veaction=edit&preload=Template:Dashboard.wikiedu.org_peer_review';
    linkClass += 'redlink';
    mouseoverText = I18n.t('assignments.sandbox_redlink_info');
  }

  return <a href={peerReviewUrl} className={linkClass} target="_blank" title={mouseoverText}>{I18n.t('assignments.peer_review_link')}</a>;
};

PeerReviewLink.propTypes = {
  assignment: PropTypes.object.isRequired,
  user: PropTypes.object.isRequired,
};

export default PeerReviewLink;
