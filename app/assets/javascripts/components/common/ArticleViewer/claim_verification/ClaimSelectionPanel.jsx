import React, { useEffect, useRef } from 'react';
import PropTypes from 'prop-types';

// The host of a source URL, shown as the link text so a student sees *where* the
// source lives (the point of the exercise) — e.g. "doi.org", "nytimes.com" —
// rather than a generic label. Falls back to null for an unparseable URL.
const sourceHost = (url) => {
  try {
    return new URL(url).hostname.replace(/^www\./, '');
  } catch (e) {
    return null;
  }
};

// The in-viewer panel shown when a student clicks a highlighted claim: the claim
// sentence, its cited source, and a button to take it on. Taking calls back to
// the exercise (an async POST), which then transitions to the taken-claim view
// without a reload. On open, focus moves into the panel (it's a dialog); the
// caller returns focus to the originating claim on close. Most labels come from
// operator-provided copy in the claim_verification locale namespace.
export const ClaimSelectionPanel = ({ claim, onTake, taking, error, onClose }) => {
  const panelRef = useRef(null);
  useEffect(() => { panelRef.current?.focus(); }, []);

  // Escape closes the panel (the caller returns focus to the originating claim).
  // The panel is intentionally non-modal — the article behind stays interactive
  // so a student can click another highlighted claim — so focus is not trapped.
  useEffect(() => {
    const handleEscape = (event) => {
      if (event.key === 'Escape') { onClose(); }
    };
    document.addEventListener('keydown', handleEscape);
    return () => document.removeEventListener('keydown', handleEscape);
  }, [onClose]);

  return (
    <aside
      ref={panelRef}
      tabIndex={-1}
      className="cv-selection-panel"
      role="dialog"
      aria-label={I18n.t('claim_verification.claim')}
    >
      <button
        type="button"
        className="cv-selection-panel__close"
        onClick={onClose}
        aria-label={I18n.t('application.cancel')}
      >
        ×
      </button>
      <section className="cv-selection-panel__claim">
        <h3 className="cv-selection-panel__label">{I18n.t('claim_verification.claim')}</h3>
        <blockquote className="cv-selection-panel__claim-text">{claim.sentence}</blockquote>
      </section>
      <section className="cv-selection-panel__source">
        <h3 className="cv-selection-panel__label">{I18n.t('claim_verification.cited_source')}</h3>
        {claim.citeText && <p className="cv-selection-panel__citation">{claim.citeText}</p>}
        {claim.sourceUrl && (
          <p>
            <a href={claim.sourceUrl} target="_blank" rel="noopener noreferrer">
              {sourceHost(claim.sourceUrl) || I18n.t('claim_verification.source_url')}
            </a>
          </p>
        )}
      </section>
      {error && <p className="cv-selection-panel__error" role="alert">{error}</p>}
      <button type="button" className="button dark cv-selection-panel__take" onClick={onTake} disabled={taking}>
        {I18n.t('claim_verification.select_claim')}
      </button>
    </aside>
  );
};

ClaimSelectionPanel.propTypes = {
  claim: PropTypes.shape({
    claimId: PropTypes.string,
    sentence: PropTypes.string,
    refId: PropTypes.string,
    citeText: PropTypes.string,
    sourceUrl: PropTypes.string,
  }).isRequired,
  onTake: PropTypes.func.isRequired,
  taking: PropTypes.bool,
  error: PropTypes.string,
  onClose: PropTypes.func.isRequired,
};

export default ClaimSelectionPanel;
