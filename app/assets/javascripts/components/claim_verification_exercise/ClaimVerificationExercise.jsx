import React, { useEffect, useState } from 'react';
import PropTypes from 'prop-types';
import { Link, useSearchParams } from 'react-router-dom';

import Loading from '@components/common/loading.jsx';
import ClaimVerificationViewer from '@components/common/ArticleViewer/containers/ClaimVerificationViewer.jsx';
import ClaimVerificationAPI from '@components/common/ArticleViewer/claim_verification/ClaimVerificationAPI';
import ArticlePicker from './ArticlePicker.jsx';
import TakenClaim from './TakenClaim.jsx';

/*
  The claim-verification exercise, as a nested route of the course SPA. It fetches
  the exercise state once and then drives the whole flow client-side — article
  picker → in-viewer claim selection → taken claim — with no page reloads. The
  current sub-view is encoded in the URL query (`?article_id=` / `?choose=1`), so
  it is back/forward- and refresh-stable, and every transition is a React Router
  navigation rather than a server round trip.
*/
const ClaimVerificationExercise = ({ course }) => {
  const [state, setState] = useState(null); // { assignment, articles }
  const [searchParams, setSearchParams] = useSearchParams();

  useEffect(() => {
    new ClaimVerificationAPI({ courseSlug: course.slug }).fetchState()
      .then(setState)
      .catch(() => setState({ assignment: null, articles: [] }));
  }, [course.slug]);

  if (!state) { return <Loading />; }

  const articleId = searchParams.get('article_id');
  const choosing = searchParams.get('choose');

  // After taking a claim, store the new assignment and clear the query so the
  // taken-claim view shows — all without a reload.
  const afterTaken = (assignment) => {
    setState(prev => ({ ...prev, assignment }));
    setSearchParams({});
  };

  if (articleId) {
    const article = state.articles.find(candidate => String(candidate.id) === articleId);
    if (article) {
      return (
        <div className="container claim-verification-exercise claim-verification-exercise--article">
          <div className="claim-verification-exercise__intro">
            <h1>{article.title}</h1>
            <p>
              <Link to="?choose=1">{I18n.t('claim_verification.choose_different_article')}</Link>
            </p>
          </div>
          <ClaimVerificationViewer article={article} course={course} onTaken={afterTaken} />
        </div>
      );
    }
  }

  if (state.assignment && !choosing) {
    return <TakenClaim assignment={state.assignment} onChooseDifferent={() => setSearchParams({ choose: '1' })} />;
  }

  return <ArticlePicker articles={state.articles} />;
};

ClaimVerificationExercise.propTypes = {
  course: PropTypes.shape({
    id: PropTypes.number,
    slug: PropTypes.string.isRequired,
  }).isRequired,
};

export default ClaimVerificationExercise;
