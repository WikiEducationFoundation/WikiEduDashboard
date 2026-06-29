import React from 'react';

import ArticleViewerShell from '@components/common/ArticleViewer/containers/ArticleViewerShell.jsx';
import useAuthorshipHighlighting from '@components/common/ArticleViewer/hooks/useAuthorshipHighlighting';

// The article viewer as used across the dashboard: the generic ArticleViewerShell
// composed with the WhoColor authorship-highlighting feature. The shell itself is
// authorship-agnostic, so other consumers can reuse it with a different highlight
// hook (e.g. claim verification) without touching any authorship code.
const ArticleViewer = props => (
  <ArticleViewerShell {...props} useHighlightFeature={useAuthorshipHighlighting} />
);

export default ArticleViewer;
