import React from 'react';

// components
import MyAssignment from '../../../containers/Assignment';
import Header from './Header';

// constants
import { REVIEWING_ROLE } from '../../../../../../constants/assignments';

export default ({ assignments, course, current_user, title, wikidataLabels }) => {
  const elements = assignments.map((assignment) => {
    return (
      <MyAssignment
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
    <section>
      <Header key={title} message={message} title={title} sub={sub} />
      {elements}
    </section>
  );
};
