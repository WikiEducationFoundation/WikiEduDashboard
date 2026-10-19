import React, { useEffect, useState } from 'react';
import PropTypes from 'prop-types';
import { useSelector } from 'react-redux';
import { format } from 'date-fns';

import Loading from '@components/common/loading.jsx';
import ClaimVerificationAPI from '@components/common/ArticleViewer/claim_verification/ClaimVerificationAPI';
import ClaimAndSource from './ClaimAndSource.jsx';
import ClaimResponse from './ClaimResponse.jsx';

const formatDate = isoDate => format(new Date(isoDate), 'MMM do, yyyy');

/*
  One student's fact-verification work, in the Assignments tab grader: each
  response they submitted, with the claim and source it answers, then the
  claim they are working on if they haven't submitted for it yet. A student
  who hasn't taken a claim has nothing here; the grader's status says so.

  Everyone's responses come in one fetch, kept as the grader steps from
  student to student (this stays mounted while only `username` changes).
*/
const ClaimVerificationWork = ({ username }) => {
  const courseSlug = useSelector(state => state.course.slug);
  const [data, setData] = useState(null); // { form, responses, pending }
  const [failed, setFailed] = useState(false);

  useEffect(() => {
    new ClaimVerificationAPI({ courseSlug }).fetchResponses()
      .then(setData)
      .catch(() => setFailed(true));
  }, [courseSlug]);

  if (failed) { return <p role="alert">{I18n.t('claim_verification.form.submit_failed')}</p>; }
  if (!data) { return <Loading />; }

  const responses = data.responses.filter(response => response.username === username);
  const pending = data.pending.filter(assignment => assignment.username === username);

  return (
    <div className="cv-grader">
      {responses.map(response => (
        <div className="cv-grader__item" key={`response-${response.id}`}>
          <p className="cv-grader__date">
            {I18n.t('claim_verification.responses.submitted_at',
                    { date: formatDate(response.created_at) })}
          </p>
          <ClaimResponse form={data.form} response={response} headingLevel={5} />
        </div>
      ))}
      {pending.map(assignment => (
        <div className="cv-grader__item" key={`pending-${assignment.id}`}>
          <p className="cv-grader__date">
            {I18n.t('claim_verification.responses.taken_at',
                    { date: formatDate(assignment.taken_at) })}
          </p>
          <ClaimAndSource claim={assignment.claim} headingLevel={5} />
        </div>
      ))}
    </div>
  );
};

ClaimVerificationWork.propTypes = {
  username: PropTypes.string.isRequired,
};

export default ClaimVerificationWork;
