export default (articlesById, assignments = [], student) => {
  const assignmentsByArticleId = assignments.reduce((acc, assignment) => ({
    ...acc,
    [assignment.article_id]: assignment
  }), {});

  const articles = articlesById[student.id] || [];
  return articles.filter(article => !assignmentsByArticleId[article.id]);
};
