import PropTypes from 'prop-types';

/*
  Reading the fact-verification exercise's form definition — the steps and
  questions the server sends from config/claim_verification_exercise.yml, with
  their copy already resolved. The form and the submitted-answers summary share
  this so both stay ignorant of what the exercise actually asks.

  Answers are one flat object keyed by question id, matching how they're stored.
*/

// A step or question may be gated on earlier answers (`visible_when`: question
// id → what opens it — the answers that do, or `true` for any answer at all).
// Ungated ones are always asked. Mirrors ClaimVerification::AnswerGate, which
// applies the same rules again on submission.
const gateOpen = (visibleWhen, answers) => (
  Object.entries(visibleWhen || {}).every(
    ([questionId, opensOn]) => (
      opensOn === true ? Boolean(answers[questionId]) : opensOn.includes(answers[questionId])
    )
  )
);

// The questions to ask under a step right now — none at all when the step's own
// gate is closed, which is how a whole step (the verify-the-claim one) waits on
// an earlier answer.
export const visibleQuestions = (step, answers) => (
  gateOpen(step.visible_when, answers)
    ? step.questions.filter(question => gateOpen(question.visible_when, answers))
    : []
);

// Required questions currently being asked but not yet answered — what keeps
// the submit button disabled. Free-text questions are never required.
export const missingRequired = (form, answers) => (
  form.steps
    .flatMap(step => visibleQuestions(step, answers))
    .filter(question => question.required && !answers[question.id])
    .map(question => question.id)
);

// A choice question's options no longer offered but still on record, so an
// older response's answer can be read back (and shown while being edited).
export const retiredOptions = question => question.retired_options || [];

// How to show one stored answer: a choice's option label — offered or retired —
// or the text as typed. Falls back to the raw value so an answer whose option
// has since been renamed still displays instead of vanishing.
const displayValue = (question, value) => {
  if (question.type !== 'choice') { return value; }
  return [...question.options, ...retiredOptions(question)]
    .find(option => option.value === value)?.label || value;
};

/*
  A submitted response as question-and-answer pairs, in the order the exercise
  asks them. Driven by what's actually stored rather than by the gates, so a
  response saved under an older version of the exercise still shows everything
  the student said.
*/
export const answeredQuestions = (form, answers = {}) => (
  form.steps
    .flatMap(step => step.questions)
    .filter(question => answers[question.id])
    .map(question => ({
      id: question.id,
      label: question.label,
      value: displayValue(question, answers[question.id]),
    }))
);

const questionPropType = PropTypes.shape({
  id: PropTypes.string.isRequired,
  type: PropTypes.oneOf(['choice', 'text']).isRequired,
  label: PropTypes.string,
  required: PropTypes.bool,
  visible_when: PropTypes.object,
  options: PropTypes.arrayOf(PropTypes.shape({
    value: PropTypes.string.isRequired,
    label: PropTypes.string,
  })),
  retired_options: PropTypes.arrayOf(PropTypes.shape({
    value: PropTypes.string.isRequired,
    label: PropTypes.string,
  })),
});

export const formPropType = PropTypes.shape({
  steps: PropTypes.arrayOf(PropTypes.shape({
    id: PropTypes.string.isRequired,
    heading: PropTypes.string,
    instructions: PropTypes.string,
    visible_when: PropTypes.object,
    questions: PropTypes.arrayOf(questionPropType).isRequired,
  })).isRequired,
});
