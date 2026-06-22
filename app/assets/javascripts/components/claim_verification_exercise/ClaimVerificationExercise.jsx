import React, { useEffect, useState } from 'react';
import PropTypes from 'prop-types';

import Loading from '@components/common/loading.jsx';
import ClaimVerificationAPI from '@components/common/ArticleViewer/claim_verification/ClaimVerificationAPI';
import ArticlePicker from './ArticlePicker.jsx';
import TakenClaim from './TakenClaim.jsx';

/*
  The claim-verification exercise, as a nested route of the course SPA. It fetches
  the exercise state once and drives the whole flow client-side with no page
  reloads. The article picker is the resting view: each article tile is its own
  ArticleViewer that opens the article (and its in-context claim selection) in
  place and closes back to the grid. Taking a claim transitions to the taken-claim
  view, which becomes the resting view once the student has a claim; "choose a
  different claim" returns to the picker.

  Deep-linking reuses the ArticleViewer shell's own `?showArticle=<id>` permalink:
  opening a tile pushes it, closing strips it, so the open article is refresh-
  stable and shareable. On load we read that id, force the picker into view (so the
  link opens even when a claim is already taken) and auto-open the matching tile.
  Because the shell manages that query param via the History API directly,
  "choosing" is kept as local state rather than a second, competing query param.
*/
const ClaimVerificationExercise = ({ course }) => {
  const [state, setState] = useState(null); // { assignment, articles }
  const [choosing, setChoosing] = useState(false);

  useEffect(() => {
    new ClaimVerificationAPI({ courseSlug: course.slug }).fetchState()
      .then(setState)
      .catch(() => setState({ assignment: null, articles: [] }));
  }, [course.slug]);

  if (!state) { return <Loading />; }

  // The article opened via the shell's ?showArticle= permalink (deep link or
  // refresh), read fresh each render — the shell keeps it in sync as the viewer
  // opens and closes.
  const showArticleId = Number(new URLSearchParams(window.location.search).get('showArticle'));

  const afterTaken = (assignment) => {
    // The viewer was open when the claim was taken, so its ?showArticle= permalink
    // is still in the URL. Clear it so the taken-claim view shows and a refresh
    // doesn't reopen the article.
    window.history.replaceState(null, null, window.location.pathname);
    setState(prev => ({ ...prev, assignment }));
    setChoosing(false);
  };

  if (state.assignment && !choosing && !showArticleId) {
    return (
      <TakenClaim
        assignment={state.assignment}
        onChooseDifferent={() => setChoosing(true)}
      />
    );
  }

  return (
    <ArticlePicker
      articles={state.articles}
      course={course}
      onTaken={afterTaken}
      showArticleId={showArticleId}
    />
  );
};

ClaimVerificationExercise.propTypes = {
  course: PropTypes.shape({
    id: PropTypes.number,
    slug: PropTypes.string.isRequired,
  }).isRequired,
};

export default ClaimVerificationExercise;
