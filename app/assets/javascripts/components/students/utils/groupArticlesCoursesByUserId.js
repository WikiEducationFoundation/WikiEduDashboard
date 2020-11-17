// This function organizes the articles data to be sorted by userId first,
// followed by the articleId.
export default (articles) => {
  return articles.reduce((acc, article) => {
    article.user_ids.forEach((id) => {
      if (acc[id]) {
        acc[id].push(article);
      } else {
        acc[id] = [article];
      }
    });
    return acc;
  }, {});
};
