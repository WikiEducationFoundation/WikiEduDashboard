import React from 'react';
import MyAssignment from './my_assignment.jsx';
import { REVIEWING_ROLE, IMPROVING_ARTICLE, NEW_ARTICLE, REVIEWING_ARTICLE } from '../../constants/assignments';

// Helper Components
const Tooltip = ({ message, text }) => {
  return (
    <div className="tooltip-trigger">
      <small className="peer-review-count">{text}</small>
      <div className="tooltip dark">
        <p>
          {message}
        </p>
      </div>
    </div>
  );
};

const Heading = ({ message, sub, title }) => {
  const smallText = (
    <Tooltip message={message} text={sub} />
  );
  return (
    <h4 className="mb1 mt2">{title} { sub && smallText }</h4>
  );
};

const List = ({ assignments, course, current_user, title, wikidataLabels }) => {
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
      <Heading key={title} message={message} title={title} sub={sub} />
      { elements }
    </section>
  );
};

// Main Component
const MyAssignmentsList = ({ assignments, course, current_user, wikidataLabels }) => {
  if (!assignments.length && current_user.isStudent) {
    return <p>{I18n.t('assignments.none_short')}</p>;
  }

  const articles = {
    new: assignments.filter(({ article_status: status }) => status === NEW_ARTICLE),
    improving: assignments.filter(({ article_status: status }) => status === IMPROVING_ARTICLE),
    reviewing: assignments.filter(({ article_status: status }) => status === REVIEWING_ARTICLE)
  };

  const listProps = { course, current_user, wikidataLabels };
  return (
    <>
      {
        articles.new.length
        ? <List {...listProps} assignments={articles.new} title="Articles I will create" />
        : null
      }
      {
        articles.improving.length
        ? <List {...listProps} assignments={articles.improving} title="Articles I'm updating" />
        : null
      }
      {
        articles.reviewing.length
        ? <List {...listProps} assignments={articles.reviewing} title="Articles I'm peer reviewing" />
        : null
      }
    </>
  );
};

export default MyAssignmentsList;
