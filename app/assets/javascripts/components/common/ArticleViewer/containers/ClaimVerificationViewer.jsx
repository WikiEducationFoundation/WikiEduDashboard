import React from 'react';

import ArticleViewerShell from '@components/common/ArticleViewer/containers/ArticleViewerShell.jsx';
import useClaimHighlighting from '@components/common/ArticleViewer/hooks/useClaimHighlighting';

// The article viewer for the claim-verification exercise: the generic
// ArticleViewerShell composed with the claim-highlighting feature instead of
// authorship. It is the main content of the exercise page (not a modal popped
// over the SPA), so it opens on mount and hides the permalink. The shell stays
// authorship-agnostic; all claim behavior lives in the injected hook.
const ClaimVerificationViewer = props => (
  <ArticleViewerShell
    {...props}
    showOnMount
    showPermalink={false}
    useHighlightFeature={useClaimHighlighting}
  />
);

export default ClaimVerificationViewer;
