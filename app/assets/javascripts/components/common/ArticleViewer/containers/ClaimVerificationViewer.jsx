import React from 'react';
import PropTypes from 'prop-types';

import ArticleViewerShell from '@components/common/ArticleViewer/containers/ArticleViewerShell.jsx';
import useClaimHighlighting from '@components/common/ArticleViewer/hooks/useClaimHighlighting';

// The article viewer for the claim-verification exercise: the generic
// ArticleViewerShell composed with the claim-highlighting feature instead of
// authorship. It opens on mount and hides the permalink (the course SPA owns the
// URL). The shell stays authorship-agnostic; all claim behavior lives in the
// injected hook. `onTaken` is bound into the hook here (rather than threaded
// through the shell) since it's specific to how this viewer is used in the flow:
// when the student takes a claim, the exercise transitions to the taken view.
const ClaimVerificationViewer = ({ onTaken, ...props }) => {
  const useClaimFeature = args => useClaimHighlighting({ ...args, onTaken });
  return (
    <ArticleViewerShell
      {...props}
      showOnMount
      showPermalink={false}
      useHighlightFeature={useClaimFeature}
    />
  );
};

ClaimVerificationViewer.propTypes = {
  onTaken: PropTypes.func.isRequired,
};

export default ClaimVerificationViewer;
