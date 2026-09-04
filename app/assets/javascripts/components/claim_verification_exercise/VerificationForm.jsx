import React, { useState } from 'react';
import PropTypes from 'prop-types';

import ClaimVerificationAPI from '@components/common/ArticleViewer/claim_verification/ClaimVerificationAPI';
import markdownIt from '~/app/assets/javascripts/utils/markdown_it';
import { formPropType, visibleQuestions, missingRequired, retiredOptions } from './formDefinition';

// Step instructions are operator copy that may link out (eg to the Reliable
// Sources policy), so they render as Markdown with bare URLs linkified and
// opening in a new tab — the exercise itself stays in the tab behind.
const md = markdownIt({ openLinksExternally: true });

const StepInstructions = ({ instructions }) => (
  <div
    className="cv-form__step-instructions"
    dangerouslySetInnerHTML={{ __html: md.render(instructions) }}
  />
);

StepInstructions.propTypes = {
  instructions: PropTypes.string.isRequired,
};

// The options to show: those offered, plus — checked but disabled — a retired
// one when it is the student's recorded answer, so a response saved before an
// option was dropped still reads correctly while being edited. Picking an
// offered option replaces it; it can't be chosen again.
const shownOptions = (question, value) => [
  ...question.options,
  ...retiredOptions(question)
    .filter(option => option.value === value)
    .map(option => ({ ...option, retired: true })),
];

// One multiple-choice question as a fieldset of radios. Both the question and
// its options are operator copy resolved server-side, so this knows none of it.
const ChoiceQuestion = ({ question, value, onChange }) => (
  <fieldset className="cv-form__question">
    <legend className="cv-form__question-label">{question.label}</legend>
    {shownOptions(question, value).map(option => (
      <label key={option.value} className="cv-form__option">
        <input
          type="radio"
          name={question.id}
          value={option.value}
          checked={value === option.value}
          disabled={option.retired}
          onChange={() => onChange(option.value)}
        />
        <span>{option.label}</span>
      </label>
    ))}
  </fieldset>
);

ChoiceQuestion.propTypes = {
  question: PropTypes.object.isRequired,
  value: PropTypes.string,
  onChange: PropTypes.func.isRequired,
};

const TextQuestion = ({ question, value, onChange }) => (
  <div className="cv-form__question">
    <label className="cv-form__question-label" htmlFor={`cv-form-${question.id}`}>
      {question.label}
    </label>
    <textarea
      id={`cv-form-${question.id}`}
      className="cv-form__textarea"
      rows={3}
      value={value || ''}
      onChange={event => onChange(event.target.value)}
    />
  </div>
);

TextQuestion.propTypes = {
  question: PropTypes.object.isRequired,
  value: PropTypes.string,
  onChange: PropTypes.func.isRequired,
};

/*
  The verification form — the whole exercise happens here in the dashboard, not
  in a sandbox. Which steps it asks, in what order, and what each question
  accepts all come from `form`, the definition the server sends from
  config/claim_verification_exercise.yml. So this component renders the exercise
  without knowing what the exercise is: refining it is a change to that file and
  its copy, not to this file.

  Steps and questions can be gated on an earlier answer (`visible_when`), which
  is how the verify-the-claim step waits until the student says they got the
  source. Answers are held in one hash keyed by question id; the server drops
  whatever the student's path didn't ask, so answers left behind by a changed
  choice are harmless. Submitting upserts, so the same form serves both first
  submission and later edits (`initial`).
*/
const VerificationForm = ({ courseSlug, form, initial, onSaved, onCancel }) => {
  const [answers, setAnswers] = useState(initial?.answers || {});
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState(false);

  const answer = (questionId, value) => (
    setAnswers(current => ({ ...current, [questionId]: value }))
  );

  const submittable = !saving && missingRequired(form, answers).length === 0;

  const submit = (event) => {
    event.preventDefault();
    setSaving(true);
    setError(false);
    new ClaimVerificationAPI({ courseSlug }).submitResponse(answers).then(({ response }) => {
      onSaved(response);
    }).catch(() => {
      setError(true);
      setSaving(false);
    });
  };

  return (
    <form className="cv-form" onSubmit={submit}>
      {form.steps.map(step => (
        visibleQuestions(step, answers).length > 0 && (
          <section className="cv-form__step" key={step.id}>
            {step.heading && <h2 className="cv-form__step-heading">{step.heading}</h2>}
            {step.instructions && <StepInstructions instructions={step.instructions} />}
            {visibleQuestions(step, answers).map(question => (
              question.type === 'choice' ? (
                <ChoiceQuestion
                  key={question.id}
                  question={question}
                  value={answers[question.id]}
                  onChange={value => answer(question.id, value)}
                />
              ) : (
                <TextQuestion
                  key={question.id}
                  question={question}
                  value={answers[question.id]}
                  onChange={value => answer(question.id, value)}
                />
              )
            ))}
          </section>
        )
      ))}

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
  form: formPropType.isRequired,
  // The already-submitted response when editing; null on first submission.
  initial: PropTypes.object,
  onSaved: PropTypes.func.isRequired,
  // Present only when editing an existing response (returns to the summary).
  onCancel: PropTypes.func,
};

export default VerificationForm;
