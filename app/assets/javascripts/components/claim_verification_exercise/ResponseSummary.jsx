import React from 'react';
import PropTypes from 'prop-types';

// One question-and-answer pair of a submitted response. Skips unanswered
// questions (conditional steps, blank open fields) so the summary only shows
// what the student actually said.
const Answer = ({ question, children }) => {
  if (!children) { return null; }
  return (
    <div className="cv-response__answer">
      <dt>{question}</dt>
      <dd>{children}</dd>
    </div>
  );
};

Answer.propTypes = {
  question: PropTypes.string.isRequired,
  children: PropTypes.node,
};

/*
  A submitted response, rendered as the questions the student answered — shared
  by the student's own post-submission view (where `onEdit` reopens the form)
  and the instructor's per-student cards (no `onEdit`). Question wording reuses
  the form's operator copy so students and instructors read the same exercise.
*/
export const ResponseSummary = ({ response, onEdit }) => (
  <div className="cv-response">
    <dl className="cv-response__answers">
      <Answer question={I18n.t('claim_verification.form.source_access_question')}>
        {I18n.t(`claim_verification.form.source_access_options.${response.source_access}`)}
      </Answer>
      <Answer question={I18n.t('claim_verification.form.source_access_notes_label')}>
        {response.source_access_notes}
      </Answer>
      {response.verdict && (
        <Answer question={I18n.t('claim_verification.form.verdict_question')}>
          {I18n.t(`claim_verification.form.verdict_options.${response.verdict}`)}
        </Answer>
      )}
      <Answer question={I18n.t('claim_verification.form.claim_location_label')}>
        {response.claim_location}
      </Answer>
      <Answer question={I18n.t('claim_verification.form.verification_notes_label')}>
        {response.verification_notes}
      </Answer>
      <Answer question={I18n.t('claim_verification.form.other_comments_label')}>
        {response.other_comments}
      </Answer>
    </dl>
    {onEdit && (
      <button type="button" className="button" onClick={onEdit}>
        {I18n.t('claim_verification.form.edit_response')}
      </button>
    )}
  </div>
);

ResponseSummary.propTypes = {
  response: PropTypes.shape({
    source_access: PropTypes.string.isRequired,
    source_access_notes: PropTypes.string,
    verdict: PropTypes.string,
    claim_location: PropTypes.string,
    verification_notes: PropTypes.string,
    other_comments: PropTypes.string,
  }).isRequired,
  onEdit: PropTypes.func,
};

export default ResponseSummary;
