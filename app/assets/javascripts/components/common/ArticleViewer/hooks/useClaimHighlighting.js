import React, { useEffect, useState } from 'react';

// Components
import ClaimSelectionPanel from '@components/common/ArticleViewer/claim_verification/ClaimSelectionPanel.jsx';
import ClaimLegend from '@components/common/ArticleViewer/claim_verification/ClaimLegend.jsx';

// Helpers
import ClaimVerificationAPI from '@components/common/ArticleViewer/claim_verification/ClaimVerificationAPI';
import formatRevisionDate from '~/app/assets/javascripts/utils/format_revision_date';

/*
  Claim-verification highlighting feature for the ArticleViewer shell.

  This hook owns everything claim-specific: fetching the server-annotated article
  HTML (the article's parsed HTML with each cited claim's citation marker tagged
  `cv-claim` + data attributes), responding to clicks on those markers, and
  rendering the selection panel where the student takes a claim on.

  It plugs into ArticleViewerShell as that shell's injected highlight feature and
  renders what this hook returns — `{ html, legend, buttonLabel, pending,
  onInnerHTMLClick, overlay }`. The shell knows nothing about claims. Unlike
  useAuthorshipHighlighting (which waits for `parsedSettle` because it needs the
  redirect-resolved title), this hook keys on `isOpen` + `revisionId`: the
  annotation endpoint identifies the article by id, so it can fetch in parallel
  with the shell's parse rather than after it.

  Taking a claim is an async POST; on success the hook calls `onTaken` with the
  resulting assignment so the exercise can transition to the taken-claim view
  without a reload.

  Claims belong to the flagged revision the article opens at (the shell's
  `initialRevisionId`), so we fetch the annotation for whichever revision is shown
  and clear it when the student toggles to the current version (which carries no
  harvested claims). A failed parse or fetch also leaves the plain article in place.
*/
const useClaimHighlighting = ({ article, course, revisionId, isOpen, onTaken }) => {
  const [annotatedHtml, setAnnotatedHtml] = useState(null);
  const [selectedClaim, setSelectedClaim] = useState(null);
  const [pending, setPending] = useState(false);
  const [taking, setTaking] = useState(false);

  // Fetch the annotated article as soon as the viewer opens at a flagged
  // revision — in parallel with the shell's own parse, not after it. The
  // annotation endpoint keys on article id + revision (not the resolved title),
  // so it needn't wait for parse to settle; firing it concurrently lets the
  // highlights and legend arrive with the article instead of a round-trip later.
  // Toggling to the current version (revisionId null) clears the annotation
  // (no harvested claims there); a failed fetch leaves the plain article.
  useEffect(() => {
    setSelectedClaim(null);
    if (!isOpen || !revisionId) {
      setAnnotatedHtml(null);
      return;
    }
    setPending(true);
    new ClaimVerificationAPI({ courseSlug: course.slug })
      .fetchAnnotatedArticle(article.id, revisionId)
      .then((data) => {
        setAnnotatedHtml(data.html);
        setPending(false);
      })
      .catch(() => {
        setAnnotatedHtml(null);
        setPending(false);
      });
  }, [isOpen, revisionId]);

  // Delegated click on the injected HTML: select the claim whose tagged citation
  // marker was clicked. Non-marker clicks (other article links) are ignored.
  const onInnerHTMLClick = (event) => {
    const marker = event.target.closest('.cv-claim');
    if (!marker) { return; }
    event.preventDefault();
    setSelectedClaim({
      claimId: marker.getAttribute('data-claim-id'),
      sentence: marker.getAttribute('data-sentence'),
      refId: marker.getAttribute('data-ref-id'),
      citeText: marker.getAttribute('data-cite-text'),
      sourceUrl: marker.getAttribute('data-source-url'),
    });
  };

  // Take the selected (already-harvested) claim on by id, then hand the new
  // assignment back to the exercise to transition the view.
  const takeClaim = () => {
    setTaking(true);
    new ClaimVerificationAPI({ courseSlug: course.slug })
      .take({ articleId: article.id, verificationClaimId: selectedClaim.claimId })
      .then((data) => {
        setTaking(false);
        onTaken(data.assignment);
      })
      .catch(() => setTaking(false));
  };

  // Pinned to the top of the article (the shell's `banner` slot): a notice that
  // this is the article at the flagged revision (a point in time, not the
  // current version), plus the claim-picking instructions. Shown only while the
  // annotated flagged revision is in view.
  const banner = annotatedHtml
    ? (
      <div className="cv-pick-banner">
        {article.mw_rev_timestamp && (
          <p className="cv-revision-notice">
            {I18n.t('claim_verification.revision_notice', {
              date: formatRevisionDate(article.mw_rev_timestamp)
            })}
          </p>
        )}
        <p>{I18n.t('claim_verification.pick_instructions')}</p>
      </div>
    )
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

  // Footer legend: while the annotation loads, a "loading claims" indicator;
  // once it arrives, the count of highlighted claims plus a jump-to-next control.
  // Each harvested claim is one `.cv-claim` marker in the annotated HTML.
  const claimCount = annotatedHtml ? (annotatedHtml.match(/\bcv-claim\b/g) || []).length : 0;
  const legend = revisionId && (pending || claimCount)
    ? <ClaimLegend count={claimCount} pending={pending} />
    : null;

  return {
    html: annotatedHtml,
    banner,
    legend,
    buttonLabel: null,
    pending,
    onInnerHTMLClick,
    overlay,
  };
};

export default useClaimHighlighting;
