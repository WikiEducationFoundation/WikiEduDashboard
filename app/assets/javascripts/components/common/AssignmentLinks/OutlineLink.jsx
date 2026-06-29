import React from 'react';
import PropTypes from 'prop-types';

export const OutlineLink = ({ assignment }) => {
  const sandboxExists = assignment.outline_sandbox_status !== 'does_not_exist';
  const sandboxUrl = assignment.sandboxUrl || assignment.sandbox_url;
  let linkClass = '';
  let mouseoverText;

  let url = `${sandboxUrl}/Outline`;
  if (!sandboxExists) {
    url += '?veaction=edit&preload=Template:Dashboard.wikiedu.org_outline';
    linkClass += 'redlink';
    mouseoverText = I18n.t('assignments.sandbox_redlink_info');
  }
  return <a href={url} className={linkClass} target="_blank" title={mouseoverText}>{I18n.t('assignments.outline') }</a>;
};

OutlineLink.propTypes = {
  // props
  assignment: PropTypes.object.isRequired,
};

export default OutlineLink;
