import React from 'react';
import PropTypes from 'prop-types';

// The in-viewer panel shown when a student clicks a highlighted claim: the claim
// sentence, its cited source, and a button to take it on. Taking calls back to
// the exercise (an async POST), which then transitions to the taken-claim view
// without a reload. All labels come from operator-provided copy in the
// claim_verification locale namespace.
export const ClaimSelectionPanel = ({ claim, onTake, taking, onClose }) => (
  <aside className="cv-selection-panel" role="dialog" aria-label={I18n.t('claim_verification.claim')}>
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
            {I18n.t('claim_verification.source_url')}
          </a>
        </p>
      )}
    </section>
    <button type="button" className="button dark" onClick={onTake} disabled={taking}>
      {I18n.t('claim_verification.select_claim')}
    </button>
  </aside>
);

ClaimSelectionPanel.propTypes = {
  claim: PropTypes.shape({
    sentence: PropTypes.string,
    refId: PropTypes.string,
    citeText: PropTypes.string,
    sourceUrl: PropTypes.string,
  }).isRequired,
  onTake: PropTypes.func.isRequired,
  taking: PropTypes.bool,
  onClose: PropTypes.func.isRequired,
};

export default ClaimSelectionPanel;
