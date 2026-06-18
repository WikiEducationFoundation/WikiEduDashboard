import React from 'react';
import PropTypes from 'prop-types';

/*
  The student's taken claim: the claim, its cited source, and the handoff to do
  the verification in their Wikipedia sandbox. "Choose a different claim" returns
  to the picker client-side (no reload).

  The bracketed [COPY — …] strings are operator placeholders carried verbatim
  from the server-rendered view; the copy pass for them is still pending, so they
  are intentionally NOT localized yet. The claim and source values are data.
*/
export const TakenClaim = ({ assignment, onChooseDifferent }) => {
  const { claim, sandbox_url: sandboxUrl } = assignment;

  return (
    <div className="container narrow claim-verification-exercise">
      <div className="claim-verification-exercise__intro">
        <h1>{I18n.t('claim_verification.your_selected_claim')}</h1>
      </div>

      <section className="claim-verification-exercise__claim">
        <h2 className="claim-verification-exercise__label">{I18n.t('claim_verification.claim')}</h2>
        <blockquote className="claim-verification-exercise__claim-text">{claim.sentence}</blockquote>
        {claim.article_url && (
          <p className="claim-verification-exercise__article-link">
            <a href={claim.article_url} target="_blank" rel="noopener noreferrer">
              {I18n.t('claim_verification.find_in_article')}
            </a>
          </p>
        )}
        {claim.context && (
          <details className="claim-verification-exercise__context">
            <summary>{I18n.t('claim_verification.show_surrounding')}</summary>
            <p>{claim.context}</p>
          </details>
        )}
      </section>

      <section className="claim-verification-exercise__source">
        <h2 className="claim-verification-exercise__label">{I18n.t('claim_verification.cited_source')}</h2>
        {claim.cite_text && <p className="claim-verification-exercise__citation">{claim.cite_text}</p>}
        {claim.source_url ? (
          <a
            href={claim.source_url}
            className="button dark claim-verification-exercise__source-link"
            target="_blank"
            rel="noopener noreferrer"
          >
            {I18n.t('claim_verification.source_url')}
          </a>
        ) : (
          <p className="claim-verification-exercise__no-source">
            [COPY — note shown when the citation has no online source the student can open]
          </p>
        )}
      </section>

      <section className="claim-verification-exercise__sandbox">
        <p>
          [COPY — instructions: open your sandbox (it will be preloaded with a
          worksheet) and write whether the source supports the claim, with reasoning]
        </p>
        <a
          href={sandboxUrl}
          className="button border claim-verification-exercise__sandbox-link"
          target="_blank"
          rel="noopener noreferrer"
        >
          [COPY — button label, eg &quot;Start in your sandbox&quot;]
        </a>
      </section>

      <div className="claim-verification-exercise__switch">
        <button
          type="button"
          className="claim-verification-exercise__switch-button"
          onClick={onChooseDifferent}
        >
          [COPY — link text, eg &quot;Choose a different claim&quot;]
        </button>
      </div>
    </div>
  );
};

TakenClaim.propTypes = {
  assignment: PropTypes.shape({
    claim: PropTypes.object.isRequired,
    sandbox_url: PropTypes.string,
  }).isRequired,
  onChooseDifferent: PropTypes.func.isRequired,
};

export default TakenClaim;
