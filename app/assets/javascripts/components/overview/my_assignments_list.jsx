import React from 'react';
import MyAssignment from './my_assignment.jsx';
import { IMPROVING_ARTICLE, NEW_ARTICLE, REVIEWING_ARTICLE } from '../../constants/assignments';

// Helper Components
const Heading = ({ title }) => (
  <h4 className="mb1 mt2">{title}</h4>
);

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

  return (
    <section>
      <Heading key={title} title={title} />
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
    new: assignments.filter(({ status }) => status === NEW_ARTICLE),
    improving: assignments.filter(({ status }) => status === IMPROVING_ARTICLE),
    reviewing: assignments.filter(({ status }) => status === REVIEWING_ARTICLE)
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
