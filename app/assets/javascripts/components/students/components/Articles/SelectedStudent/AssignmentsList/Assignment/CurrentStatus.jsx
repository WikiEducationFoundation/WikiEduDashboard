import React from 'react';
import PropTypes from 'prop-types';

const STATUSES = {
  not_yet_started: I18n.t('article_statuses.not_yet_started'),

  // assignments
  in_progress: I18n.t('article_statuses.in_progress'),
  ready_for_review: I18n.t('article_statuses.ready_for_review'),
  ready_for_mainspace: I18n.t('article_statuses.ready_for_mainspace'),
  assignment_completed: I18n.t('article_statuses.assignment_completed'),

  // reviewing
  reading_the_article: I18n.t('article_statuses.reading_the_article'),
  providing_feedback: I18n.t('article_statuses.providing_feedback'),
  post_to_talk: I18n.t('article_statuses.post_to_talk'),
  peer_review_completed: I18n.t('article_statuses.peer_review_completed')
};

export const CurrentStatus = ({ current, statuses }) => (
  <>
    <span>{ statuses.indexOf(current) + 1 }/{ statuses.length }. </span>
    { STATUSES[current] }
  </>
);

CurrentStatus.propTypes = {
  current: PropTypes.string,
  statuses: PropTypes.arrayOf(PropTypes.string).isRequired
};

export default CurrentStatus;
