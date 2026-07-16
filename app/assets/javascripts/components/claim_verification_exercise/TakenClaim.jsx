import React, { useState } from 'react';
import PropTypes from 'prop-types';

import VerificationForm from './VerificationForm.jsx';
import ResponseSummary from './ResponseSummary.jsx';

/*
  The student's taken claim: the claim, its cited source, and the verification
  form (steps 3 and 4 of the exercise) — the whole exercise happens here in the
  dashboard. Once a response is submitted the form gives way to a summary of
  their answers (editable, since submitting is an upsert). Responses are keyed
  per claim, so choosing a different claim stays available even after
  submitting — the summary belongs to this claim and survives a switch. The
  claim and source values are data.
*/
export const TakenClaim = ({ assignment, response, courseSlug, onChooseDifferent, onResponseSaved }) => {
  const { claim } = assignment;
  const [editing, setEditing] = useState(false);

  const saved = (savedResponse) => {
    setEditing(false);
    onResponseSaved(savedResponse);
  };

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
            {I18n.t('claim_verification.no_online_source')}
          </p>
        )}
      </section>

      {response && !editing ? (
        <section className="claim-verification-exercise__response">
          <h2 className="claim-verification-exercise__label">
            {I18n.t('claim_verification.form.submitted_heading')}
          </h2>
          <ResponseSummary response={response} onEdit={() => setEditing(true)} />
        </section>
      ) : (
        <VerificationForm
          courseSlug={courseSlug}
          initial={response}
          onSaved={saved}
          onCancel={editing ? () => setEditing(false) : null}
        />
      )}

      <div className="claim-verification-exercise__switch">
        <button
          type="button"
          className="claim-verification-exercise__switch-button"
          onClick={onChooseDifferent}
        >
          {I18n.t('claim_verification.choose_different_claim')}
        </button>
      </div>
    </div>
  );
};

TakenClaim.propTypes = {
  assignment: PropTypes.shape({
    claim: PropTypes.object.isRequired,
  }).isRequired,
  // The submitted response, if any.
  response: PropTypes.object,
  courseSlug: PropTypes.string.isRequired,
  onChooseDifferent: PropTypes.func.isRequired,
  onResponseSaved: PropTypes.func.isRequired,
};

export default TakenClaim;
