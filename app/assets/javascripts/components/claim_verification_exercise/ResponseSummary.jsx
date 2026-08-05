import React from 'react';
import PropTypes from 'prop-types';

import { formPropType, answeredQuestions } from './formDefinition';

/*
  A submitted response, rendered as the questions the student answered — shared
  by the student's own post-submission view (where `onEdit` reopens the form),
  the instructor's per-student cards and the students-tab popover (no `onEdit`).

  Both the questions and their wording come from the same form definition the
  student filled in, so students and instructors always read the same exercise.
  Only answered questions appear: an unanswered optional question, or a step the
  student's path skipped, is simply absent.
*/
export const ResponseSummary = ({ form, response, onEdit }) => (
  <div className="cv-response">
    <dl className="cv-response__answers">
      {answeredQuestions(form, response.answers).map(({ id, label, value }) => (
        <div className="cv-response__answer" key={id}>
          <dt>{label}</dt>
          <dd>{value}</dd>
        </div>
      ))}
    </dl>
    {onEdit && (
      <button type="button" className="button" onClick={onEdit}>
        {I18n.t('claim_verification.form.edit_response')}
      </button>
    )}
  </div>
);

ResponseSummary.propTypes = {
  form: formPropType.isRequired,
  response: PropTypes.shape({
    answers: PropTypes.object,
  }).isRequired,
  onEdit: PropTypes.func,
};

export default ResponseSummary;
