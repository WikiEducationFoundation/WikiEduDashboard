import React from 'react';
import MyAssignment from './my_assignment.jsx';
import { REVIEWING_ROLE, IMPROVING_ARTICLE, NEW_ARTICLE, REVIEWING_ARTICLE } from '../../../constants/assignments';

// Helper Functions
const filterStatus = status => ({ article_status }) => {
  return status === article_status;
};

const sortBy = key => (a, b) => {
  return a[key] > b[key] ? 1 : -1;
};

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

const NoAssignmentMessage = () => (
  <section className="no-assignment-message">
    <p>You have not chosen an article to work on. Lorem ipsum dolor sit amet, consectetur adipiscing elit. Aenean molestie, lectus id consequat placerat, elit ligula sodales risus, non fringilla felis eros sed elit.</p>
    <aside>
      <a href="/training/students/finding-your-article" target="_blank" className="button ghost-button">
        How to find an article
      </a>
      <a href="/training/students/evaluating-articles" target="_blank" className="button ghost-button">
        Evaluating articles and sources
      </a>
    </aside>
  </section>
);

// Main Component
const MyAssignmentsList = ({ assignments, course, current_user, wikidataLabels }) => {
  if (!assignments.length && current_user.isStudent) {
    return Features.wikiEd ? <NoAssignmentMessage /> : <p>{I18n.t('assignments.none_short')}</p>;
  }

  const articles = {
    new: assignments.filter(filterStatus(NEW_ARTICLE)).sort(sortBy('article_title')),
    improving: assignments.filter(filterStatus(IMPROVING_ARTICLE)).sort(sortBy('article_title')),
    reviewing: assignments.filter(filterStatus(REVIEWING_ARTICLE)).sort(sortBy('article_title'))
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
