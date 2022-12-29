import { fetchArticles } from '../../actions/articles_actions';
import { fetchAssignments } from '../../actions/assignment_actions';
import { fetchUsers } from '../../actions/user_actions';

// this tells us if the data is stale and needs to be refreshed
/**
 * @param  {number} lastRequestTimestamp - UNIX timestamp in milliseconds
 * @param  {number} staleTime - in milliseconds (default: 60 seconds)
 * @returns {boolean}
*/

export const isStale = (lastRequestTimestamp, staleTime = 60 * 1000) => {
  const now = Date.now();
  return Math.abs(now - lastRequestTimestamp) > staleTime;
};

// used to refresh stale data on the following routes:
// 1. /courses/:course_school/:course_title/students/*
// 2. /courses/:course_school/:course_title/articles/*
// The data is refreshed only if it is stale (older than 60 seconds)
export const refreshData = (location, args, dispatch) => {
  const {
    lastUserRequestTimestamp,
    courseSlug,
    articlesLimit,
    lastRequestArticleTimestamp,
    lastRequestAssignmentTimestamp
  } = args;

  // if we're on either of the student's routes, refresh the student data
  if (location.pathname.match(/\/.+students\/(overview|articles).*/)) {
    if (courseSlug !== null && courseSlug !== undefined && isStale(lastUserRequestTimestamp)) {
      dispatch(fetchUsers(courseSlug));
    }
  }

  // if we're on the articles route, refresh the article data
  if (location.pathname.includes('/articles/edited')) {
    if (courseSlug !== null && courseSlug !== undefined && isStale(lastRequestArticleTimestamp)) {
      dispatch(fetchArticles(courseSlug, articlesLimit, true));
    }
  }

  // as for the assignments, we refresh the data if we're on the assignments route or the student's overview route(which also shows the assignments)
  if (location.pathname.includes('/articles/assigned') || location.pathname.match(/\/.+students\/(overview|articles).*/)) {
    if (courseSlug !== null && courseSlug !== undefined && isStale(lastRequestAssignmentTimestamp)) {
      dispatch(fetchAssignments(courseSlug));
    }
  }
};
