import React from 'react';
import PropTypes from 'prop-types';

// components
import Assignment from '@components/overview/my_articles/containers/Assignment.jsx';
import Header from './Header/Header.jsx';

// constants
import { REVIEWING_ROLE } from '~/app/assets/javascripts/constants/assignments';

export const List = ({ assignments, course, current_user, title, wikidataLabels }) => {
  const elements = assignments.map((assignment) => {
    return (
      <Assignment
        assignment={assignment}
        course={course}
        current_user={current_user}
        key={assignment.id}
        username={current_user.username}
        wikidataLabels={wikidataLabels}
      />
    );
  });

  const { peer_review_count: total } = course;
  const currentCount = assignments.length;
  const isReviewing = assignments[0].role === REVIEWING_ROLE;
  const sub = total && isReviewing ? `(${currentCount}/${total})` : null;
  const message = I18n.t('assignments.peer_review_count_tooltip', { total });

  return (
    <>
      <Header key={title} message={message} title={title} sub={sub} />
      {elements}
    </>
  );
};

List.propTypes = {
  // props
  assignments: PropTypes.array.isRequired,
  course: PropTypes.object.isRequired,
  current_user: PropTypes.object.isRequired,
  title: PropTypes.string.isRequired,
  wikidataLabels: PropTypes.object.isRequired,
};

export default List;
