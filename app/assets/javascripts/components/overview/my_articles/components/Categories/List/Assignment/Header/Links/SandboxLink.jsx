import React from 'react';
import PropTypes from 'prop-types';

// constants
import { NEW_ARTICLE } from '~/app/assets/javascripts/constants/assignments';

export const SandboxLink = ({ assignment }) => {
  let url = assignment.sandboxUrl;
  if (assignment.status === NEW_ARTICLE) {
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
