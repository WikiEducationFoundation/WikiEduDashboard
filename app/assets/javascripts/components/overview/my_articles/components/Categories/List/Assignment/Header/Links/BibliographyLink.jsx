import React from 'react';

export default ({ assignment }) => {
  const url = `${assignment.sandboxUrl}/Bibliography?veaction=edit&preload=Template:Dashboard.wikiedu.org_bibliography`;
  return <a href={url} target="_blank">{I18n.t('assignments.bibliography')}</a>;
};
