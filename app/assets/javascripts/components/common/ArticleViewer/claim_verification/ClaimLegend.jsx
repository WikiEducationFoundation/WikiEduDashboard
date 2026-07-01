import React from 'react';
import PropTypes from 'prop-types';

// The claim-verification footer legend: how many claims are highlighted, which
// one is current ("Claim X of N"), and prev/next controls that step the active
// claim (cycling). Mirrors the authorship legend's "scroll to next highlight"
// affordance, but for the `.cv-claim` markers. Active state and navigation live
// in the parent hook (useClaimHighlighting); this component is presentational.
const ClaimLegend = ({ total, activeIndex, onPrev, onNext, pending }) => {
  // The highlights load a beat after the article (a second, server-side parse),
  // so show that the claims are on their way rather than an empty footer.
  if (pending) {
    return (
      <div className="cv-legend cv-legend--pending" aria-live="polite">
        <span className="cv-legend__count">{I18n.t('claim_verification.loading_claims')}</span>
      </div>
    );
  }

  if (!total) { return null; }

  const label = activeIndex == null
    ? I18n.t('claim_verification.claims_highlighted', { count: total })
    : I18n.t('claim_verification.claim_position', { current: activeIndex + 1, total });

  return (
    <div className="cv-legend">
      <span className="cv-legend__count" aria-live="polite">{label}</span>
      <span className="cv-legend__nav">
        <button type="button" className="cv-legend__btn" onClick={onPrev}>
          {I18n.t('claim_verification.previous_claim')}
        </button>
        <button type="button" className="cv-legend__btn" onClick={onNext}>
          {I18n.t('claim_verification.next_claim')}
        </button>
      </span>
    </div>
  );
};

ClaimLegend.propTypes = {
  total: PropTypes.number,
  activeIndex: PropTypes.number,
  onPrev: PropTypes.func,
  onNext: PropTypes.func,
  pending: PropTypes.bool,
};

export default ClaimLegend;
