export const delayFetchAssignmentsAndArticles = (props, cb) => {
  const { loadingArticles, loadingAssignments } = props;
  if (!loadingArticles && !loadingAssignments) return cb();

  const requests = [];
  if (loadingAssignments) {
    requests.push(props.fetchAssignments(props.course_id));
  }
  if (loadingArticles) {
    requests.push(props.fetchArticles(props.course_id, props.limit));
  }

  Promise.all(requests).then(() => setTimeout(cb, 750));
};
