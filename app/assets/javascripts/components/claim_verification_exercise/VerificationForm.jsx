import React, { useState } from 'react';
import PropTypes from 'prop-types';

import ClaimVerificationAPI from '@components/common/ArticleViewer/claim_verification/ClaimVerificationAPI';

export const SOURCE_ACCESS_VALUES = ['accessed', 'nonexistent', 'inaccessible'];
export const VERDICT_VALUES = [
  'full_support', 'mostly_supports', 'partial_support', 'mostly_unsupported',
  'unsupported', 'contradicted', 'undetermined'
];

// One multiple-choice question as a fieldset of radios. All strings are
// operator copy from the claim_verification.form locale namespace.
const RadioQuestion = ({ name, question, optionsKey, values, value, onChange }) => (
  <fieldset className="cv-form__question">
    <legend className="cv-form__question-label">{question}</legend>
    {values.map(optionValue => (
      <label key={optionValue} className="cv-form__option">
        <input
          type="radio"
          name={name}
          value={optionValue}
          checked={value === optionValue}
          onChange={() => onChange(optionValue)}
        />
        <span>{I18n.t(`claim_verification.form.${optionsKey}.${optionValue}`)}</span>
      </label>
    ))}
  </fieldset>
);

RadioQuestion.propTypes = {
  name: PropTypes.string.isRequired,
  question: PropTypes.string.isRequired,
  optionsKey: PropTypes.string.isRequired,
  values: PropTypes.arrayOf(PropTypes.string).isRequired,
  value: PropTypes.string,
  onChange: PropTypes.func.isRequired,
};

const OpenQuestion = ({ name, label, value, onChange }) => (
  <div className="cv-form__question">
    <label className="cv-form__question-label" htmlFor={`cv-form-${name}`}>{label}</label>
    <textarea
      id={`cv-form-${name}`}
      className="cv-form__textarea"
      rows={3}
      value={value}
      onChange={event => onChange(event.target.value)}
    />
  </div>
);

OpenQuestion.propTypes = {
  name: PropTypes.string.isRequired,
  label: PropTypes.string.isRequired,
  value: PropTypes.string.isRequired,
  onChange: PropTypes.func.isRequired,
};

/*
  The verification form itself — the whole exercise now happens here in the
  dashboard, not in a sandbox. Step 3 (find the source) is always asked; its
  tell-us-more field appears only when the student couldn't get the source.
  Step 4 (verify the claim) appears only when they could: its two open
  questions are self-selecting by their own phrasing ("If you were able…",
  "If you were unable…"), so both are always visible within the step. The
  final catch-all comments field applies on every path. Submitting upserts,
  so the same form serves both first submission and later edits (`initial`).
*/
const VerificationForm = ({ courseSlug, initial, onSaved, onCancel }) => {
  const [sourceAccess, setSourceAccess] = useState(initial?.source_access || null);
  const [sourceAccessNotes, setSourceAccessNotes] = useState(initial?.source_access_notes || '');
  const [verdict, setVerdict] = useState(initial?.verdict || null);
  const [claimLocation, setClaimLocation] = useState(initial?.claim_location || '');
  const [verificationNotes, setVerificationNotes] = useState(initial?.verification_notes || '');
  const [otherComments, setOtherComments] = useState(initial?.other_comments || '');
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState(false);

  const sourceAccessed = sourceAccess === 'accessed';
  // The multiple-choice answers are the only required ones; the server clears
  // answers for steps that don't apply, so stale hidden fields are harmless.
  const submittable = sourceAccess && (!sourceAccessed || verdict) && !saving;

  const submit = (event) => {
    event.preventDefault();
    setSaving(true);
    setError(false);
    new ClaimVerificationAPI({ courseSlug }).submitResponse({
      source_access: sourceAccess,
      source_access_notes: sourceAccessNotes,
      verdict,
      claim_location: claimLocation,
      verification_notes: verificationNotes,
      other_comments: otherComments,
    }).then(({ response }) => {
      onSaved(response);
    }).catch(() => {
      setError(true);
      setSaving(false);
    });
  };

  return (
    <form className="cv-form" onSubmit={submit}>
      <section className="cv-form__step">
        <h2 className="cv-form__step-heading">{I18n.t('claim_verification.form.step_find_source')}</h2>
        <p className="cv-form__step-instructions">{I18n.t('claim_verification.form.find_source_instructions')}</p>
        <RadioQuestion
          name="source_access"
          question={I18n.t('claim_verification.form.source_access_question')}
          optionsKey="source_access_options"
          values={SOURCE_ACCESS_VALUES}
          value={sourceAccess}
          onChange={setSourceAccess}
        />
        {sourceAccess && !sourceAccessed && (
          <OpenQuestion
            name="source_access_notes"
            label={I18n.t('claim_verification.form.source_access_notes_label')}
            value={sourceAccessNotes}
            onChange={setSourceAccessNotes}
          />
        )}
      </section>

      {sourceAccessed && (
        <section className="cv-form__step">
          <h2 className="cv-form__step-heading">{I18n.t('claim_verification.form.step_verify')}</h2>
          <p className="cv-form__step-instructions">{I18n.t('claim_verification.form.verify_instructions')}</p>
          <RadioQuestion
            name="verdict"
            question={I18n.t('claim_verification.form.verdict_question')}
            optionsKey="verdict_options"
            values={VERDICT_VALUES}
            value={verdict}
            onChange={setVerdict}
          />
          <OpenQuestion
            name="claim_location"
            label={I18n.t('claim_verification.form.claim_location_label')}
            value={claimLocation}
            onChange={setClaimLocation}
          />
          <OpenQuestion
            name="verification_notes"
            label={I18n.t('claim_verification.form.verification_notes_label')}
            value={verificationNotes}
            onChange={setVerificationNotes}
          />
        </section>
      )}

      <section className="cv-form__step">
        <OpenQuestion
          name="other_comments"
          label={I18n.t('claim_verification.form.other_comments_label')}
          value={otherComments}
          onChange={setOtherComments}
        />
      </section>

      {error && <p className="cv-form__error" role="alert">{I18n.t('claim_verification.form.submit_failed')}</p>}

      <div className="cv-form__actions">
        <button type="submit" className="button dark" disabled={!submittable}>
          {I18n.t('claim_verification.form.submit')}
        </button>
        {onCancel && (
          <button type="button" className="button" onClick={onCancel}>
            {I18n.t('application.cancel')}
          </button>
        )}
      </div>
    </form>
  );
};

VerificationForm.propTypes = {
  courseSlug: PropTypes.string.isRequired,
  // The already-submitted response when editing; null on first submission.
  initial: PropTypes.object,
  onSaved: PropTypes.func.isRequired,
  // Present only when editing an existing response (returns to the summary).
  onCancel: PropTypes.func,
};

export default VerificationForm;
