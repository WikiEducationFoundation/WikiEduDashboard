import React, { useEffect, useState } from 'react';
import PropTypes from 'prop-types';
import { Link, useLocation } from 'react-router-dom';
import { format } from 'date-fns';

import Loading from '@components/common/loading.jsx';
import ClaimVerificationAPI from '@components/common/ArticleViewer/claim_verification/ClaimVerificationAPI';
import ClaimResponse from './ClaimResponse.jsx';

const formatDate = isoDate => format(new Date(isoDate), 'MMM do, yyyy');

// "Real Name (username)" when the enrollment has a real name, else username —
// matching how the students tab identifies students to instructors.
const studentName = ({ username, real_name: realName }) => (
  realName ? `${realName} (${username})` : username
);

// A pending row's claim: just the sentence and its article, since there are no
// answers yet to check against the source.
const PendingClaim = ({ claim }) => (
  <div className="cv-response-card__claim">
    <blockquote>{claim.sentence}</blockquote>
    {claim.article_title && (
      <p className="cv-response-card__article-title">{claim.article_title}</p>
    )}
  </div>
);

PendingClaim.propTypes = {
  claim: PropTypes.shape({
    sentence: PropTypes.string,
    article_title: PropTypes.string,
  }).isRequired,
};

/*
  Every student's submissions on one page, at /verify_claim/responses, where
  the course has no Assignments tab to grade them in one student at a time
  (see ResponsesPage, which otherwise forwards there): every submitted
  response as a card — the student, then their claim
  and its cited source exactly as the student saw them (so each answer can be
  checked against the citation and the source itself), then their answers
  rendered with the same question wording the student saw — followed by
  students who have taken a claim but not yet submitted. A
  `?student=<username>` param narrows the page to one student — that's the
  per-student deep link — with a back link to the full list. The preview link
  opens the exercise itself, which instructors can do (and even complete) like
  a student.
*/
const InstructorResponses = ({ course }) => {
  const [data, setData] = useState(null); // { form, responses, pending }
  const [failed, setFailed] = useState(false);
  const studentFilter = new URLSearchParams(useLocation().search).get('student');

  useEffect(() => {
    new ClaimVerificationAPI({ courseSlug: course.slug }).fetchResponses()
      .then(setData)
      .catch(() => setFailed(true));
  }, [course.slug]);

  if (failed) {
    return (
      <div className="container narrow claim-verification-responses">
        <p role="alert">{I18n.t('system_stats.errors.fetch_failed')}</p>
      </div>
    );
  }
  if (!data) { return <Loading />; }

  const byStudent = entry => !studentFilter || entry.username === studentFilter;
  const responses = data.responses.filter(byStudent);
  const pending = data.pending.filter(byStudent);

  return (
    <div className="container narrow claim-verification-responses">
      {studentFilter && (
        <div className="cv-preview-return">
          <Link to={`/courses/${course.slug}/verify_claim/responses`}>
            ← {I18n.t('claim_verification.responses.heading')}
          </Link>
        </div>
      )}
      <div className="claim-verification-exercise__intro claim-verification-responses__header">
        <h1>{I18n.t('claim_verification.responses.heading')}</h1>
        <Link className="button" to={`/courses/${course.slug}/verify_claim`}>
          {I18n.t('claim_verification.responses.preview_exercise')}
        </Link>
      </div>

      {(responses.length === 0 && pending.length === 0) && (
        <p className="claim-verification-exercise__empty">
          {I18n.t('claim_verification.responses.none_yet')}
        </p>
      )}

      {responses.map(response => (
        <article className="cv-response-card" key={response.id}>
          <header className="cv-response-card__header">
            <div>
              <h2>{studentName(response)}</h2>
              {response.claim.article_title && (
                <p className="cv-response-card__article-title">{response.claim.article_title}</p>
              )}
            </div>
            <span className="cv-response-card__date">
              {I18n.t('claim_verification.responses.submitted_at',
                      { date: formatDate(response.created_at) })}
            </span>
          </header>
          <ClaimResponse form={data.form} response={response} headingLevel={3} />
        </article>
      ))}

      {pending.length > 0 && (
        <section className="cv-response-pending">
          <h2>{I18n.t('claim_verification.responses.pending_heading')}</h2>
          {pending.map(assignment => (
            <article className="cv-response-card cv-response-card--pending" key={assignment.id}>
              <header className="cv-response-card__header">
                <h3>{studentName(assignment)}</h3>
                <span className="cv-response-card__date">
                  {I18n.t('claim_verification.responses.taken_at',
                          { date: formatDate(assignment.taken_at) })}
                </span>
              </header>
              <PendingClaim claim={assignment.claim} />
            </article>
          ))}
        </section>
      )}
    </div>
  );
};

InstructorResponses.propTypes = {
  course: PropTypes.shape({
    slug: PropTypes.string.isRequired,
  }).isRequired,
};

export default InstructorResponses;
