import React from 'react';
import MyAssignment from './my_assignment.jsx';

const groupArticlesByStatus = (acc, assignment) => {
  let collection = acc.Reviewing;
  if (assignment.role === 0) {
    collection = !assignment.article_id ? acc['New Articles'] : acc['Articles I\'m improving'];
  }
  collection.push(assignment);
  return acc;
};

const organizeArticlesByStatus = (count, course, current_user, wikidataLabels) => {
  return ([key, collection]) => {
    const elements = collection.map((assignment, i) => {
      return (
        <MyAssignment
          assignment={assignment}
          course={course}
          current_user={current_user}
          key={assignment.id}
          last={i === count - 1}
          username={current_user.username}
          wikidataLabels={wikidataLabels}
        />
      );
    });
    return [
      <h4 className={`${elements.length ? '' : 'hidden'} mb1 mt2`} key={key}>{key}</h4>
    ].concat(elements);
  };
};

const MyAssignmentsList = ({ assignments, count, course, current_user, wikidataLabels }) => {
  if (!assignments.length && current_user.isStudent) return <p>{I18n.t('assignments.none_short')}</p>;

  const groupings = {
    'New Articles': [],
    'Articles I\'m improving': [],
    Reviewing: []
  };
  const grouped = assignments.reduce(groupArticlesByStatus, groupings);
  return Object.entries(grouped)
    .map(organizeArticlesByStatus(count, course, current_user, wikidataLabels));
};

export default MyAssignmentsList;
