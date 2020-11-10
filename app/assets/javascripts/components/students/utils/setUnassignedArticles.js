import { includes } from 'lodash';

export default (articlesById, assignments = [], student) => {
  // assignmentsByArticleId holds all the assignments grouped/sorted by articleIds
  // If there are mutiple assignments with the same article/article Id, then only the user_id of the
  // assigned editor is added to the assignees array. However, if no editor is assigned then
  // it is set to null.
  const assignmentsByArticleId = assignments.reduce((acc, assignment) => {
    if (acc[assignment.article_id]) {
      return {
        ...acc,
        [assignment.article_id]: {
          ...acc[assignment.article_id],
          assignees: [
            ...acc[assignment.article_id].assignees,
            assignment.user_id,
          ],
        },
      };
    }
    return {
      ...acc,
      [assignment.article_id]: {
        ...assignment,
        assignees: [assignment.user_id],
      },
    };
  }, {});
  const articles = articlesById[student.id] || [];
  // articles array is filtered to include articles edited by a user that aren't present
  // in assignmentsByArticleId. Also if an unassigned editor has edited a particular article
  // but that article is present,either as an assigned article or an available article yet
  // to be assigned, in the assignments array then that article is also included.
  return articles.filter(
    article =>
      !includes(
        !assignmentsByArticleId[article.id]
          || assignmentsByArticleId[article.id].assignees,
        student.id
      )
  );
};
