import React from 'react';
import PropTypes from 'prop-types';

// The claim-verification footer legend: how many claims are highlighted on the
// article, plus a control that jumps the article scroll to the next highlighted
// claim (cycling, looping back to the first after the last), so they're easy to
// find. Mirrors the authorship legend's "scroll to next highlight" affordance,
// but for the `.cv-claim` markers.
//
// "Current position" is read from the DOM (which `.cv-claim` carries the active
// class) rather than a React ref, so it survives the legend remounting while the
// highlights load and always wraps correctly.
const SCROLLBOX = '#article-scrollbox-id';
const ACTIVE_CLASS = 'cv-claim--active';

const ClaimLegend = ({ count, pending }) => {
  const jumpToNextClaim = () => {
    const claims = [...document.querySelectorAll(`${SCROLLBOX} .cv-claim`)];
    if (!claims.length) { return; }
    const current = claims.findIndex(el => el.classList.contains(ACTIVE_CLASS));
    const next = claims[(current + 1) % claims.length];
    claims.forEach(el => el.classList.remove(ACTIVE_CLASS));
    next.classList.add(ACTIVE_CLASS);
    next.scrollIntoView({ behavior: 'smooth', block: 'center' });
  };

  // The highlights load a beat after the article (a second, server-side parse),
  // so show that the claims are on their way rather than an empty footer.
  if (pending) {
    return (
      <div className="cv-legend cv-legend--pending" aria-live="polite">
        <span className="cv-legend__count">{I18n.t('claim_verification.loading_claims')}</span>
      </div>
    );
  }

  if (!count) { return null; }

  return (
    <div className="cv-legend">
      <span className="cv-legend__count">
        {I18n.t('claim_verification.claims_highlighted', { count })}
      </span>
      <button type="button" className="button dark small cv-legend__next" onClick={jumpToNextClaim}>
        {I18n.t('claim_verification.next_claim')}
      </button>
    </div>
  );
};

ClaimLegend.propTypes = {
  count: PropTypes.number,
  pending: PropTypes.bool,
};

export default ClaimLegend;
