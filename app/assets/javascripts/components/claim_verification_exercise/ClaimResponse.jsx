import React from 'react';
import PropTypes from 'prop-types';

import ClaimAndSource from './ClaimAndSource.jsx';
import ResponseSummary from './ResponseSummary.jsx';
import { formPropType } from './formDefinition';

/*
  A submitted response as an instructor reads it: the claim and its cited
  source as the student saw them, then the student's answers, so each answer
  can be checked against the citation and the source. Shared by the
  submissions list's cards and the Assignments tab grader. `headingLevel`
  places the section labels under the surrounding heading.
*/
export const ClaimResponse = ({ form, response, headingLevel }) => {
  const Heading = `h${headingLevel}`;

  return (
    <>
      <ClaimAndSource claim={response.claim} headingLevel={headingLevel} />
      <section className="cv-claim-response__answers">
        <Heading className="claim-verification-exercise__label">
          {I18n.t('claim_verification.form.submitted_heading')}
        </Heading>
        <ResponseSummary form={form} response={response} />
      </section>
    </>
  );
};

ClaimResponse.propTypes = {
  form: formPropType.isRequired,
  response: PropTypes.shape({
    claim: PropTypes.object.isRequired,
    answers: PropTypes.object,
  }).isRequired,
  headingLevel: PropTypes.oneOf([3, 4, 5]).isRequired,
};

export default ClaimResponse;
