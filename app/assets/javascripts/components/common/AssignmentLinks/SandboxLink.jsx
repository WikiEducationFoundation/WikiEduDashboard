import React from 'react';
import PropTypes from 'prop-types';
import { isUserSandbox } from '@components/overview/my_articles/utils/processAssignments';

export const SandboxLink = ({ assignment, editMode }) => {
  const sandboxExists = assignment.draft_sandbox_status !== 'does_not_exist';
  let url = assignment.sandboxUrl || assignment.sandbox_url;
  let linkClass = '';
  let mouseoverText;

  if (Features.wikiEd && !sandboxExists) {
    if (editMode) { url += '?veaction=edit&preload=Template:Dashboard.wikiedu.org_draft_template'; }
    linkClass += 'redlink';
    mouseoverText = I18n.t('assignments.sandbox_redlink_info');
  }

  if (isUserSandbox(assignment)) {
    linkClass += ' disabled-link';
    mouseoverText = I18n.t('assignments.sandbox_link_disabled_tooltip');
  }

  return (
    <a href={url} className={linkClass} target="_blank" title={mouseoverText} >
      {I18n.t('assignments.sandbox_draft_link')}
    </a>
  );
};

SandboxLink.propTypes = {
  // props
  assignment: PropTypes.object.isRequired,
};

export default SandboxLink;
