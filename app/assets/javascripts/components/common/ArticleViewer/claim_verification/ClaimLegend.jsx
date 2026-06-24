import React, { useRef } from 'react';
import PropTypes from 'prop-types';

// The claim-verification footer legend: how many claims are highlighted on the
// article, plus a control that jumps the article scroll to the next highlighted
// claim (cycling), so they're easy to find. Mirrors the authorship legend's
// "scroll to next highlight" affordance, but for the `.cv-claim` markers.
const SCROLLBOX = '#article-scrollbox-id';
const ACTIVE_CLASS = 'cv-claim--active';

const ClaimLegend = ({ count }) => {
  const indexRef = useRef(-1);

  const jumpToNextClaim = () => {
    const claims = document.querySelectorAll(`${SCROLLBOX} .cv-claim`);
    if (!claims.length) { return; }
    indexRef.current = (indexRef.current + 1) % claims.length;
    const claim = claims[indexRef.current];
    claim.scrollIntoView({ behavior: 'smooth', block: 'center' });
    document.querySelectorAll(`${SCROLLBOX} .${ACTIVE_CLASS}`)
      .forEach(el => el.classList.remove(ACTIVE_CLASS));
    claim.classList.add(ACTIVE_CLASS);
  };

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
};

export default ClaimLegend;
