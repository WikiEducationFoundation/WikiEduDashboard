import React, { useEffect, useState } from 'react';
import PropTypes from 'prop-types';
import { useSelector } from 'react-redux';

import Popover from '@components/common/popover.jsx';
import useOutsideClick from '~/app/assets/javascripts/hooks/useOutsideClick';
import ClaimVerificationAPI from '@components/common/ArticleViewer/claim_verification/ClaimVerificationAPI';
import ResponseSummary from './ResponseSummary.jsx';

/*
  "Submitted response" popover on a student's exercise row (Students tab
  drawer): shows that student's verification-form answers in place, with no
  navigation away from the tab. The answers are fetched lazily on first open,
  through the same viewer-scoped endpoint as the submissions page — staff can
  read any student's, a student their own.

  Open state is local rather than useExpandablePopover's: that hook shares the
  single global ui.openKey that the surrounding student drawer also uses, so
  opening this popover through it would close the drawer out from under us.
*/
const ResponsePopover = ({ student }) => {
  const courseSlug = useSelector(state => state.course.slug);
  const [isOpen, setIsOpen] = useState(false);
  const ref = useOutsideClick(() => setIsOpen(false));
  const [data, setData] = useState(null);
  const [failed, setFailed] = useState(false);

  useEffect(() => {
    if (!isOpen || data || failed) { return; }
    new ClaimVerificationAPI({ courseSlug }).fetchResponses()
      .then(setData)
      .catch(() => setFailed(true));
  }, [isOpen, data, failed, courseSlug]);

  const responses = data && data.responses.filter(r => r.username === student.username);

  let contents;
  if (failed) {
    contents = <p role="alert">{I18n.t('claim_verification.form.submit_failed')}</p>;
  } else if (!responses) {
    contents = <p>{I18n.t('claim_verification.admin.loading')}</p>;
  } else if (!responses.length) {
    contents = <p>{I18n.t('claim_verification.responses.none_yet')}</p>;
  } else {
    contents = responses.map(response => (
      <div className="cv-response-pop__item" key={response.id}>
        <blockquote>{response.claim.sentence}</blockquote>
        <ResponseSummary response={response} />
      </div>
    ));
  }

  let buttonClassName = 'button small';
  if (isOpen) { buttonClassName += ' dark'; }

  return (
    <div className="pop__container cv-response-pop" ref={ref}>
      <button className={buttonClassName} onClick={() => setIsOpen(current => !current)}>
        {I18n.t('claim_verification.form.submitted_heading')}
      </button>
      <Popover
        is_open={isOpen}
        right
        rows={<tr><td>{contents}</td></tr>}
        styles={{ width: '440px' }}
      />
    </div>
  );
};

ResponsePopover.propTypes = {
  // The student whose drawer this is.
  student: PropTypes.shape({
    id: PropTypes.number.isRequired,
    username: PropTypes.string.isRequired,
  }).isRequired,
};

export default ResponsePopover;
