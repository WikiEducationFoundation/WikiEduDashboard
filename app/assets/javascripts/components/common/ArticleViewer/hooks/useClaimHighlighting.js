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
  result — the assignment, plus the student's earlier response for that claim
  if they had one — so the exercise can transition to the taken-claim view
  without a reload.

  Claims belong to the flagged revision the article opens at (the shell's
  `initialRevisionId`), so we fetch the annotation for whichever revision is shown
  and clear it when the student toggles to the current version (which carries no
  harvested claims). A failed parse or fetch also leaves the plain article in place.
*/
const SCROLLBOX = '#article-scrollbox-id';

const useClaimHighlighting = ({ article, course, revisionId, isOpen, onTaken }) => {
  const [annotatedHtml, setAnnotatedHtml] = useState(null);
  const [selectedClaim, setSelectedClaim] = useState(null);
  const [activeIndex, setActiveIndex] = useState(null);
  const [pending, setPending] = useState(false);
  const [taking, setTaking] = useState(false);
  const [takeError, setTakeError] = useState(null);

  // Fetch the annotated article as soon as the viewer opens at a flagged
  // revision — in parallel with the shell's own parse, not after it. The
  // annotation endpoint keys on article id + revision (not the resolved title),
  // so it needn't wait for parse to settle; firing it concurrently lets the
  // highlights and legend arrive with the article instead of a round-trip later.
  // Toggling to the current version (revisionId null) clears the annotation
  // (no harvested claims there); a failed fetch leaves the plain article.
  useEffect(() => {
    setSelectedClaim(null);
    setActiveIndex(null);
    setTakeError(null);
    if (!isOpen || !revisionId) {
      setAnnotatedHtml(null);
      return undefined;
    }
    // Ignore a response that arrives after the viewer has moved on (e.g. the
    // student toggled the revision again), so a stale fetch can't overwrite the
    // current annotation or clear a newer pending state.
    let ignore = false;
    setPending(true);
    new ClaimVerificationAPI({ courseSlug: course.slug })
      .fetchAnnotatedArticle(article.id, revisionId)
      .then((data) => {
        if (ignore) { return; }
        setAnnotatedHtml(data.html);
        setPending(false);
      })
      .catch(() => {
        if (ignore) { return; }
        setAnnotatedHtml(null);
        setPending(false);
      });
    return () => { ignore = true; };
  }, [isOpen, revisionId]);

  const claimNodes = () => [...document.querySelectorAll(`${SCROLLBOX} .cv-claim`)];

  // Scroll a claim to just below the sticky banner. A plain
  // scrollIntoView({block:'start'}) lands it at the scrollbox top — *under* the
  // pinned banner, so it reads as "scrolled too far / not visible". Instead,
  // position it against the scrollbox top offset by the banner's actual height,
  // which also keeps it clear of the bottom selection panel.
  const scrollClaimIntoView = (el) => {
    const box = document.querySelector(SCROLLBOX);
    if (!box) { el.scrollIntoView({ behavior: 'smooth', block: 'center' }); return; }
    const banner = box.querySelector('.cv-pick-banner');
    const offset = (banner ? banner.getBoundingClientRect().height : 0) + 16;
    const top = box.scrollTop + el.getBoundingClientRect().top
      - box.getBoundingClientRect().top - offset;
    box.scrollTo({ top: Math.max(top, 0), behavior: 'smooth' });
  };

  // Mark the claim at `index` active (the bordered state) — the single source of
  // truth for which claim is current, shared by clicking, keyboard activation
  // and the legend's prev/next. Wraps around the ends. Optionally scrolls it into
  // view (below the banner, above the bottom panel).
  const activateClaim = (index, { scroll = false } = {}) => {
    const claims = claimNodes();
    if (!claims.length) { return null; }
    const i = ((index % claims.length) + claims.length) % claims.length;
    claims.forEach((el, j) => el.classList.toggle('cv-claim--active', j === i));
    if (scroll) { scrollClaimIntoView(claims[i]); }
    setActiveIndex(i);
    return claims[i];
  };

  const selectClaim = (marker) => {
    setTakeError(null);
    setSelectedClaim({
      claimId: marker.getAttribute('data-claim-id'),
      sentence: marker.getAttribute('data-sentence'),
      refId: marker.getAttribute('data-ref-id'),
      citeText: marker.getAttribute('data-cite-text'),
      sourceUrl: marker.getAttribute('data-source-url'),
    });
  };

  const openClaim = (marker) => {
    activateClaim(claimNodes().indexOf(marker), { scroll: true });
    selectClaim(marker);
  };

  // Delegated click on the injected HTML: open the claim whose tagged marker was
  // clicked. Non-marker clicks (other article links) are ignored.
  const onInnerHTMLClick = (event) => {
    const marker = event.target.closest('.cv-claim');
    if (!marker) { return; }
    event.preventDefault();
    openClaim(marker);
  };

  // The claim markers are focusable buttons (role=button, tabindex=0), so handle
  // Enter/Space for keyboard users; the browser fires no click for non-anchors.
  const onInnerHTMLKeyDown = (event) => {
    if (event.key !== 'Enter' && event.key !== ' ') { return; }
    const marker = event.target.closest('.cv-claim');
    if (!marker) { return; }
    event.preventDefault();
    openClaim(marker);
  };

  // Legend prev/next: step the active claim, wrapping. From no selection, "next"
  // goes to the first claim and "previous" to the last.
  const goToClaim = (delta) => {
    const start = activeIndex == null ? (delta > 0 ? -1 : 0) : activeIndex;
    activateClaim(start + delta, { scroll: true });
  };

  // Closing the panel returns focus to the claim it was opened from, so keyboard
  // users aren't dropped back at the top of the document.
  const closePanel = () => {
    setSelectedClaim(null);
    const claims = claimNodes();
    if (activeIndex != null && claims[activeIndex]) { claims[activeIndex].focus(); }
  };

  // Take the selected (already-harvested) claim on by id, then hand the new
  // assignment back to the exercise to transition the view.
  const takeClaim = () => {
    setTaking(true);
    new ClaimVerificationAPI({ courseSlug: course.slug })
      .take({ articleId: article.id, verificationClaimId: selectedClaim.claimId })
      .then((data) => {
        setTaking(false);
        onTaken(data);
      })
      .catch((error) => {
        setTaking(false);
        // 403 means the user isn't enrolled in this course; any other failure is
        // unexpected, so reuse the app's generic error copy. Shown inline in the
        // panel, since the page-level notification banner sits behind the viewer.
        const message = error.status === 403
          ? I18n.t('claim_verification.take_not_enrolled')
          : I18n.t('error_500.explanation');
        setTakeError(message);
      });
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
        <p className="cv-select-claim-note">{I18n.t('claim_verification.select_claim_instructions')}</p>
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
        error={takeError}
        onClose={closePanel}
      />
    )
    : null;

  // Footer legend: while the annotation loads, a "loading claims" indicator;
  // once it arrives, the count of highlighted claims, the current position, and
  // prev/next controls to step through them. Each harvested claim is one
  // `.cv-claim` marker in the annotated HTML.
  const claimCount = annotatedHtml ? (annotatedHtml.match(/\bcv-claim\b/g) || []).length : 0;
  const legend = revisionId && (pending || claimCount)
    ? (
      <ClaimLegend
        total={claimCount}
        activeIndex={activeIndex}
        onPrev={() => goToClaim(-1)}
        onNext={() => goToClaim(1)}
        pending={pending}
      />
    )
    : null;

  return {
    html: annotatedHtml,
    banner,
    legend,
    buttonLabel: null,
    pending,
    onInnerHTMLClick,
    onInnerHTMLKeyDown,
    overlay,
  };
};

export default useClaimHighlighting;
