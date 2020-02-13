import React from 'react';
import PropTypes from 'prop-types';

export const BibliographyLink = ({ assignment }) => {
  const sandboxUrl = assignment.sandboxUrl || assignment.sandbox_url;
  const url = `${sandboxUrl}/Bibliography?veaction=edit&preload=Template:Dashboard.wikiedu.org_bibliography`;
  return <a href={url} target="_blank">{I18n.t('assignments.bibliography')}</a>;
};

BibliographyLink.propTypes = {
  // props
  assignment: PropTypes.object.isRequired,
};

export default BibliographyLink;
