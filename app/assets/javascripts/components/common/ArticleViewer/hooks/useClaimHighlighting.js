import React, { useEffect, useState } from 'react';

// Components
import ClaimSelectionPanel from '@components/common/ArticleViewer/claim_verification/ClaimSelectionPanel.jsx';

// Helpers
import ClaimVerificationAPI from '@components/common/ArticleViewer/claim_verification/ClaimVerificationAPI';

/*
  Claim-verification highlighting feature for the ArticleViewer shell.

  This hook owns everything claim-specific: fetching the server-annotated article
  HTML (the article's parsed HTML with each cited claim's citation marker tagged
  `cv-claim` + data attributes), responding to clicks on those markers, and
  rendering the selection panel where the student takes a claim on.

  It plugs into ArticleViewerShell as that shell's injected highlight feature,
  with the same contract as useAuthorshipHighlighting: the shell drives it via
  `parsedSettle` (bumped when the shell's parsed-article fetch settles, after
  redirect resolution) and `revisionId`, and renders what this hook returns —
  `{ html, legend, buttonLabel, pending, onInnerHTMLClick, overlay }`. The shell
  knows nothing about claims.

  Taking a claim is an async POST; on success the hook calls `onTaken` with the
  resulting assignment so the exercise can transition to the taken-claim view
  without a reload.

  Claims only apply to the article's current version, so we fetch the annotation
  only when no specific revision is selected; on an old revision (or on fetch
  failure) we return `html: null` and the shell falls back to the plain parsed
  article.
*/
const useClaimHighlighting = ({ article, course, revisionId, parsedSettle, onTaken }) => {
  const [annotatedHtml, setAnnotatedHtml] = useState(null);
  const [selectedClaim, setSelectedClaim] = useState(null);
  const [pending, setPending] = useState(false);
  const [taking, setTaking] = useState(false);

  // Fetch the annotated article once the shell's parse settles for the current
  // version. A revision toggle clears the annotation (claims are current-version
  // only); a failed parse or fetch leaves the plain article in place.
  useEffect(() => {
    if (!parsedSettle) { return; }
    setSelectedClaim(null);
    if (!parsedSettle.ok || revisionId) {
      setAnnotatedHtml(null);
      return;
    }
    setPending(true);
    new ClaimVerificationAPI({ courseSlug: course.slug })
      .fetchAnnotatedArticle(article.id)
      .then((data) => {
        setAnnotatedHtml(data.html);
        setPending(false);
      })
      .catch(() => {
        setAnnotatedHtml(null);
        setPending(false);
      });
  }, [parsedSettle?.id, revisionId]);

  // Delegated click on the injected HTML: select the claim whose tagged citation
  // marker was clicked. Non-marker clicks (other article links) are ignored.
  const onInnerHTMLClick = (event) => {
    const marker = event.target.closest('.cv-claim');
    if (!marker) { return; }
    event.preventDefault();
    setSelectedClaim({
      sentence: marker.getAttribute('data-sentence'),
      refId: marker.getAttribute('data-ref-id'),
      citeText: marker.getAttribute('data-cite-text'),
      sourceUrl: marker.getAttribute('data-source-url'),
    });
  };

  // Take the selected claim on, then hand the new assignment back to the
  // exercise to transition the view.
  const takeClaim = () => {
    setTaking(true);
    new ClaimVerificationAPI({ courseSlug: course.slug })
      .take({ articleId: article.id, sentence: selectedClaim.sentence, refId: selectedClaim.refId })
      .then((data) => {
        setTaking(false);
        onTaken(data.assignment);
      })
      .catch(() => setTaking(false));
  };

  const legend = annotatedHtml
    ? <p className="cv-pick-instructions">{I18n.t('claim_verification.pick_instructions')}</p>
    : null;

  const overlay = selectedClaim
    ? (
      <ClaimSelectionPanel
        claim={selectedClaim}
        onTake={takeClaim}
        taking={taking}
        onClose={() => setSelectedClaim(null)}
      />
    )
    : null;

  return {
    html: annotatedHtml,
    legend,
    buttonLabel: null,
    pending,
    onInnerHTMLClick,
    overlay,
  };
};

export default useClaimHighlighting;
