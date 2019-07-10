import { getFiltered } from '../../utils/model_utils';
import { ASSIGNED_ROLE, REVIEWING_ROLE } from '../../constants/assignments';

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

const pluck = key => ({ [key]: val }) => val;

export const groupByAssignmentType = (assignments, user_id) => {
  const unassignedOptions = { user_id: null, role: ASSIGNED_ROLE };
  const unassigned = getFiltered(assignments, unassignedOptions);

  const assignOptions = { user_id, role: ASSIGNED_ROLE };
  const assigned = getFiltered(assignments, assignOptions);

  const reviewOptions = { user_id, role: REVIEWING_ROLE };
  const reviewing = getFiltered(assignments, reviewOptions);

  // To find articles that are able to be reviewed...
  const pluckArticleId = pluck('article_id');
  const assignedAndReviewingTitles = assigned.concat(reviewing).map(pluck('article_title'));
  const assignedArticleIds = assigned.map(pluckArticleId);
  const reviewingArticleIds = reviewing.map(pluckArticleId);

  const reviewable = assignments.filter((assignment) => {
    const articleId = assignment.article_id;
    if (!articleId && assignment.user_id !== user_id) {
      return !assignedAndReviewingTitles.includes(assignment.article_title);
    }

    return assignment.user_id // ...the article must have a user_id
      // which shouldn't match the current user's id
      && assignment.user_id !== user_id
      // and should not be an article that is assigned to them
      && !assignedArticleIds.includes(articleId)
      // and should not be an article they are already reviewing
      && !reviewingArticleIds.includes(articleId);
  });

  return { assigned, reviewing, unassigned, reviewable };
}
;
