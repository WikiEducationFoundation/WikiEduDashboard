import React from 'react';
import PropTypes from 'prop-types';

export const SandboxLink = ({ assignment }) => {
  let url = assignment.sandboxUrl || assignment.sandbox_url;
  if (Features.wikiEd) {
    url += '?veaction=edit&preload=Template:Dashboard.wikiedu.org_draft_template';
  }
  return (
    <a href={url} target="_blank">
      {I18n.t('assignments.sandbox_draft_link')}
    </a>
  );
};

SandboxLink.propTypes = {
  // props
  assignment: PropTypes.object.isRequired,
};

export default SandboxLink;
