import React from 'react';

// constants
import { NEW_ARTICLE } from '../../../../../../../../../constants/assignments';

export default ({ assignment }) => {
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
