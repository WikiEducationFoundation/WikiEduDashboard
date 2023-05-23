import React from 'react';
import PropTypes from 'prop-types';

// components
import PageViews from './PageViews';
import MarkAsIncompleteButton from './MarkAsIncompleteButton';
import RemoveButton from './RemoveButton';

import MainspaceChecklist from '~/app/assets/javascripts/components/common/mainspace_checklist.jsx';
import FinalArticleChecklist from '~/app/assets/javascripts/components/common/final_article_checklist.jsx';
import PeerReviewChecklist from '~/app/assets/javascripts/components/common/peer_review_checklist.jsx';
import Feedback from '~/app/assets/javascripts/components/common/feedback.jsx';

export const Actions = ({
  article, assignment, courseSlug, current_user, isComplete, username,
  isEnglishWikipedia, isClassroomProgram, unassign
}) => {
  if (isComplete) {
    // If complete, only return the following
    return (
      <section className="actions">
        <PageViews key="pageviews-button" article={article} />
        <MarkAsIncompleteButton
          key="mark-incomplete-button"
          assignment={assignment}
          courseSlug={courseSlug}
        />
      </section>
    );
  }

  const actions = [];

  if (assignment.article_id) {
    actions.push(<PageViews key="pageviews-button" article={article} />);
  }

  // Assigned article that does not yet exist in mainspace
  if (isEnglishWikipedia() && isClassroomProgram) {
    const feedback = (
      <Feedback
        assignment={assignment}
        current_user={current_user}
        key="feedback-button"
        username={username}
      />
    );
    if (assignment.role === 0 && !assignment.article_id) {
      actions.push(<MainspaceChecklist key="mainspace-button" />, feedback);
    } else if (assignment.role === 0) {
      actions.push(<FinalArticleChecklist key="final-article-button" />, feedback);
    } else {
      actions.push(<PeerReviewChecklist key="peer-review-button" />);
    }
  }

  return (
    <section className="actions">
      {actions}
      <RemoveButton key="remove-button" assignment={assignment} unassign={unassign} />
    </section>
  );
};

Actions.propTypes = {
  // props
  article: PropTypes.object.isRequired,
  assignment: PropTypes.object.isRequired,
  courseSlug: PropTypes.string.isRequired,
  current_user: PropTypes.object.isRequired,
  isComplete: PropTypes.bool.isRequired,
  username: PropTypes.string.isRequired,
  isClassroomProgram: PropTypes.bool.isRequired,

  // actions
  isEnglishWikipedia: PropTypes.func.isRequired,
  unassign: PropTypes.func.isRequired,
};

export default Actions;
