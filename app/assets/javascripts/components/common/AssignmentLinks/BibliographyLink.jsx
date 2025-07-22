import React from 'react';
import PropTypes from 'prop-types';

export const BibliographyLink = ({ assignment }) => {
  const sandboxExists = assignment.bibliography_sandbox_status !== 'does_not_exist';
  const sandboxUrl = assignment.sandboxUrl || assignment.sandbox_url;
  let linkClass = '';
  let mouseoverText;

  let url = `${sandboxUrl}/Bibliography`;
  if (!sandboxExists) {
    url += '?veaction=edit&preload=Template:Dashboard.wikiedu.org_bibliography';
    linkClass += 'redlink';
    mouseoverText = I18n.t('assignments.sandbox_redlink_info');
  }
  return <a href={url} className={linkClass} target="_blank" title={mouseoverText}>{I18n.t('assignments.bibliography') }</a>;
};

BibliographyLink.propTypes = {
  // props
  assignment: PropTypes.object.isRequired,
};

export default BibliographyLink;
