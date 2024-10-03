import { getFiltered } from '../../utils/model_utils';
import { ASSIGNED_ROLE, REVIEWING_ROLE } from '../../constants/assignments';
import { uniqBy, flow, flatten, compact } from 'lodash-es';

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
  // Unassigned to anyone
  const unassignedOptions = { user_id: null, role: ASSIGNED_ROLE };
  const unassigned = getFiltered(assignments, unassignedOptions);

  // Assigned to the current user
  const assignOptions = { user_id, role: ASSIGNED_ROLE };
  const assigned = getFiltered(assignments, assignOptions);

  // Assignable to the current user: unassigned, and the current user
  // isn't already assigned the same one
  const pluckArticleUrl = pluck('article_url');
  const assignedArticleUrls = assigned.map(pluckArticleUrl);
  const assignable = unassigned.filter(assignment => !assignedArticleUrls.includes(assignment.article_url));

  // The current user is reviewing
  const reviewOptions = { user_id, role: REVIEWING_ROLE };
  const reviewing = getFiltered(assignments, reviewOptions);

  // To find articles that are able to be reviewed...
  const pluckArticleId = pluck('article_id');
  const assignedArticleIds = assigned.map(pluckArticleId);
  const reviewingArticleIds = reviewing.map(pluckArticleId);

  const allAssigned = getFiltered(assignments, { role: ASSIGNED_ROLE });
  const reviewableDuplicates = allAssigned.filter((assignment) => {
    // If the article doesn't have an article id, that means it's a new article,
    // so we want to allow for new articles to be reviewable as well as long as
    // it isn't the current user's new article.
    const { article_id: id, article_title: title, project } = assignment;
    // Check that the assignment is assigned to someone else
    if (!id && assignment.user_id && assignment.user_id !== user_id) {
      const all = assigned.concat(reviewing);
      // Find similar articles that have already been assigned
      const alreadyAssigned = all.find((assign) => {
        return assign.article_title === title && assign.project === project;
      });
      // Only return if it has not been assigned
      return !alreadyAssigned;
    }

    return assignment.user_id // ...the article must have a user_id
      // which shouldn't match the current user's id
      && assignment.user_id !== user_id
      // and should not be an article that is assigned to them
      && !assignedArticleIds.includes(id)
      // and should not be an article they are already reviewing
      && !reviewingArticleIds.includes(id);
  });

  const reviewable = uniqBy(reviewableDuplicates, 'article_url');
  return { assigned, reviewing, unassigned, reviewable, assignable };
};

export const getModulesAndBlocksFromWeeks = (weeks) => {
  const flattenAndCompact = flow([flatten, compact]);
  const blocks = flatten(weeks.map(week => week.blocks));
  const modules = flattenAndCompact(blocks.map(block => block.training_modules));
  return { blocks, modules };
};

// Here we're working around the quirks of react-router version 5.
// When parsing route params, react-router doesn't return the same values as
// the native JavaScript utils like encodeURIComponent and decodeURIComponent.
// We need to handle cases where the username param that comes from a router `match`
// object is not the same as the actual username.
// Examples include:
//   CaesSion? — ends in question mark
//   Wikster808% — includes a percent sign, which react-router doesn't like.
//   If you ain't runnin' game, Say my name — comma causes problems.
// Upgrading to react-router 6 and the history 5 might (or might not) fix these issues.
export const selectUserByUsernameParam = (users, usernameParam) => {
  if (!usernameParam) return null;

  let selectedUser = users.find(({ username }) => username === usernameParam);
  if (selectedUser) return selectedUser;

  selectedUser = users.find(({ username }) => username.replace(',', '%2C') === usernameParam);
  if (selectedUser) return selectedUser;

  selectedUser = users.find(({ username }) => username.replace('?', '%3F') === usernameParam);
  return selectedUser;
};

export const canUserCreateAccount = async () => {
  const response = await fetch('https://en.wikipedia.org/w/api.php?action=query&meta=userinfo&uiprop=cancreateaccount&format=json&origin=*');
  const data = await response.json();

  // cancreateaccounterror is present if the user cannot create an account
  // looks something like this
  //   {
  //     "code": "blocked",
  //     "type": "error",
  //     “message”: "blockedtext”,
  //     "params": [] -> contains actual error message. Is an array of strings.
  //   }

  return !data.query.userinfo.cancreateaccounterror;
};
