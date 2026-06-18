import React from 'react';
import PropTypes from 'prop-types';

// The in-viewer panel shown when a student clicks a highlighted claim: the claim
// sentence, its cited source, and a button to take it on. Taking submits a plain
// POST to the take route (full-page nav to the taken-claim page), mirroring the
// server-rendered flow it replaces. All labels come from operator-provided copy
// in the claim_verification locale namespace.
const csrfToken = () => document.querySelector('meta[name="csrf-token"]')?.content || '';

export const ClaimSelectionPanel = ({ claim, article, course, onClose }) => (
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
    <form method="post" action={`/courses/${course.slug}/verify_claim/take`}>
      <input type="hidden" name="authenticity_token" value={csrfToken()} />
      <input type="hidden" name="article_id" value={article.id} />
      <input type="hidden" name="ref_id" value={claim.refId} />
      <input type="hidden" name="sentence" value={claim.sentence} />
      <button type="submit" className="button dark">
        {I18n.t('claim_verification.select_claim')}
      </button>
    </form>
  </aside>
);

ClaimSelectionPanel.propTypes = {
  claim: PropTypes.shape({
    sentence: PropTypes.string,
    refId: PropTypes.string,
    citeText: PropTypes.string,
    sourceUrl: PropTypes.string,
  }).isRequired,
  article: PropTypes.shape({ id: PropTypes.number }).isRequired,
  course: PropTypes.shape({ slug: PropTypes.string }).isRequired,
  onClose: PropTypes.func.isRequired,
};

export default ClaimSelectionPanel;
