import React, { useEffect, useState } from 'react';
import PropTypes from 'prop-types';
import { useDispatch } from 'react-redux';
import { useLocation } from 'react-router-dom';

import Loading from '@components/common/loading.jsx';
import { fetchTimeline } from '~/app/assets/javascripts/actions/timeline_actions';
import ClaimVerificationAPI from '@components/common/ArticleViewer/claim_verification/ClaimVerificationAPI';
import ArticlePicker from './ArticlePicker.jsx';
import TakenClaim from './TakenClaim.jsx';
import InstructorResponses from './InstructorResponses.jsx';

/*
  The claim-verification exercise, as a nested route of the course SPA.
  `/verify_claim` is the exercise itself, for every role — instructors can walk
  through (and even complete) it exactly as a student would. The instructor
  view of everyone's submissions lives on its own sub-page,
  `/verify_claim/responses`, linked from the timeline module row and from each
  student's exercise listing (the JSON behind it is instructor-gated
  server-side).

  For the exercise it fetches the state once and drives the whole flow
  client-side with no page reloads. The article picker is the resting view:
  each article tile is its own ArticleViewer that opens the article (and its
  in-context claim selection) in place and closes back to the grid. Taking a
  claim transitions to the taken-claim view — where the verification form
  lives — which becomes the resting view once the student has a claim; "choose
  a different claim" returns to the picker. Responses are keyed per claim, so
  switching claims after submitting is allowed (the earlier response stays with
  its claim, and re-taking that claim brings the submitted answers back).

  Deep-linking reuses the ArticleViewer shell's own `?showArticle=<id>` permalink:
  opening a tile pushes it, closing strips it, so the open article is refresh-
  stable and shareable. On load we read that id, force the picker into view (so the
  link opens even when a claim is already taken) and auto-open the matching tile.
  Because the shell manages that query param via the History API directly,
  "choosing" is kept as local state rather than a second, competing query param.
*/
const ClaimVerificationExercise = ({ course }) => {
  const [state, setState] = useState(null); // { assignment, response, articles }
  const [choosing, setChoosing] = useState(false);
  const responsesPage = useLocation().pathname.endsWith('/responses');
  const dispatch = useDispatch();

  useEffect(() => {
    if (responsesPage) { return; }
    new ClaimVerificationAPI({ courseSlug: course.slug }).fetchState()
      .then(setState)
      .catch(() => setState({ assignment: null, response: null, articles: [] }));
  }, [course.slug, responsesPage]);

  if (responsesPage) { return <InstructorResponses course={course} />; }
  if (!state) { return <Loading />; }

  // The article opened via the shell's ?showArticle= permalink (deep link or
  // refresh), read fresh each render — the shell keeps it in sync as the viewer
  // opens and closes.
  const showArticleId = Number(new URLSearchParams(window.location.search).get('showArticle'));

  const afterTaken = ({ assignment, response }) => {
    // The viewer was open when the claim was taken, so its ?showArticle= permalink
    // is still in the URL. Clear it so the taken-claim view shows and a refresh
    // doesn't reopen the article.
    window.history.replaceState(null, null, window.location.pathname);
    setState(prev => ({ ...prev, assignment, response: response || null }));
    setChoosing(false);
  };

  const afterResponseSaved = (response) => {
    setState(prev => ({ ...prev, response }));
    // Submitting completed the exercise's training module; refresh the
    // timeline store so navigating back there shows it complete without a
    // page reload.
    dispatch(fetchTimeline(course.slug));
  };

  if (state.assignment && !choosing && !showArticleId) {
    return (
      <TakenClaim
        assignment={state.assignment}
        response={state.response}
        courseSlug={course.slug}
        onChooseDifferent={() => setChoosing(true)}
        onResponseSaved={afterResponseSaved}
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
