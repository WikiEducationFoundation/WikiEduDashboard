import React, { useState } from 'react';
import PropTypes from 'prop-types';
import { connect } from 'react-redux';
import { initiateConfirm } from '../../../actions/confirm_actions';
import { randomPeerAssignments } from '../../../actions/assignment_actions';
import { REVIEWING_ROLE } from '../../../constants';
import ArticleUtils from '../../../utils/article_utils';

const RandomPeerAssignButton = ({
  randomPeerAssignments: assignRandomPeer,
  initiateConfirm: confirmInitiate,
  course,
  current_user,
  assignments,
  students
}) => {
  const [hover, setHover] = useState();
  const randomPeerAssign = () => {
    const peerReviewCount = course.peer_review_count || 1;
    const currentlyReviewing = assignments.filter(assignment => assignment.role === REVIEWING_ROLE).length;
    const randomAssignmentsCount = (students.length * peerReviewCount) - currentlyReviewing;

    let confirmMessage;
    let onConfirm;
    if (randomAssignmentsCount <= 0) {
      confirmMessage = I18n.t(`assignments.random_peer_review.${ArticleUtils.projectSuffix(course.home_wiki.project, 'limit_exceeded')}`, { maximum: peerReviewCount });
      onConfirm = () => {};
    } else {
      confirmMessage = I18n.t(`assignments.random_peer_review.${ArticleUtils.projectSuffix(course.home_wiki.project, 'confirm_addition')}`, { count: randomAssignmentsCount, maximum: peerReviewCount });
      onConfirm = () => assignRandomPeer({ course_slug: course.slug });
    }

    confirmInitiate({ confirmMessage, onConfirm });
  };

  if (!current_user.isAdvancedRole) {
    return <div />;
  }

  return (
    <div className="tooltip-trigger" onMouseEnter={() => setHover(true)} onMouseLeave={() => setHover(false)}>
      <button className="button border small assign-button" onClick={randomPeerAssign}>
        {I18n.t('assignments.random_peer_review.heading')} {<span className={`${hover ? 'tooltip-indicator-hover' : 'tooltip-indicator'}`}/>}
      </button>
      <div className="tooltip">
        <p>
          {I18n.t(`assignments.random_peer_review.${ArticleUtils.projectSuffix(course.home_wiki.project, 'tooltip_message')}`)}
        </p>
      </div>
    </div>
  );
};

RandomPeerAssignButton.propTypes = {
  randomPeerAssignments: PropTypes.func,
  initiateConfirm: PropTypes.func,
  course: PropTypes.object,
  current_user: PropTypes.object,
  assignments: PropTypes.array,
  students: PropTypes.array
};

const mapDispatchToProps = {
  randomPeerAssignments,
  initiateConfirm
};

export default connect(null, mapDispatchToProps)(RandomPeerAssignButton);
