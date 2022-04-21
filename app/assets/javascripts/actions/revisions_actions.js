
import {
  RECEIVE_REVISIONS,
  REVISIONS_LOADING,
  RECEIVE_COURSE_SCOPED_REVISIONS,
  COURSE_SCOPED_REVISIONS_LOADING,
  SORT_REVISIONS,
  API_FAIL,
  RECEIVE_ASSESSMENTS,
  RECEIVE_REFERENCES
} from '../constants';
import { fetchWikidataLabelsForRevisions } from './wikidata_actions';
import logErrorMessage from '../utils/log_error_message';
import request from '../utils/request';
import { fetchRevisionsFromUsers } from '../utils/mediawiki_revisions_utils';
import { fetchRevisionsAndReferences } from './media_wiki_revisions_actions';
import { sortRevisionsByDate } from '../utils/revision_utils';
import { INCREASE_LIMIT } from '../constants/revisions';
import { STUDENT_ROLE } from '../constants/user_roles';

const fetchAllArticles = async (course) => {
  const response = await request(`/courses/${course.slug}/articles.json?limit=500`);
  if (!response.ok) {
    logErrorMessage(response);
    const data = await response.text();
    response.responseText = data;
    throw response;
  }
  return response.json();
};

const fetchRevisionsPromise = async (course, users, last_date, dispatch) => {
  const { revisions, last_date: new_last_date } = await fetchRevisionsFromUsers(course, users, 7, last_date);
  course.revisions = sortRevisionsByDate(revisions);

  // we don't await this. When the assessments/references get laoded, the action is dispatched
  fetchRevisionsAndReferences(revisions, dispatch);
  return { course, last_date: new_last_date };
};
const fetchRevisionsCourseSpecificPromise = async (course, users, last_date) => {
  const result = await fetchAllArticles(course);
  const { revisions, last_date: new_last_date } = await fetchRevisionsFromUsers(course, users, 7, last_date);
  const trackedArticles = new Set(result.course.articles.filter(article => article.tracked).map(article => article.title));
  const trackedRevisions = revisions.filter(revision => trackedArticles.has(revision.title));

  course.revisions = sortRevisionsByDate(trackedRevisions);
  return { course, last_date: new_last_date };
};

export const fetchRevisions = course => async (dispatch, getState) => {
  dispatch({ type: REVISIONS_LOADING });
  const state = getState();
  const users = state.users.users.filter(user => user.role === STUDENT_ROLE);
  if (users.length === 0) {
    course.revisions = [];
    dispatch({
      type: RECEIVE_REVISIONS,
      data: { course },
    });
    dispatch({
      type: RECEIVE_REFERENCES,
      data: { },
    });
    dispatch({
      type: RECEIVE_ASSESSMENTS,
      data: { },
    });
    return;
  }
  if (state.revisions.revisionsDisplayed.length < state.revisions.revisions.length) {
    // no need to fetch new revisions
    return dispatch({
      type: INCREASE_LIMIT
    });
  }
  return (
    fetchRevisionsPromise(course, users, state.revisions.last_date, dispatch)
      .then((resp) => {
        dispatch({
          type: RECEIVE_REVISIONS,
          data: resp,
        });
        fetchWikidataLabelsForRevisions(resp.course.revisions, dispatch);
      })
      .catch(response => (dispatch({ type: API_FAIL, data: response })))
  );
};

export const fetchCourseScopedRevisions = (course, limit) => async (dispatch, getState) => {
  const state = getState();
  const users = state.users.users.filter(user => user.role === STUDENT_ROLE);
  dispatch({ type: COURSE_SCOPED_REVISIONS_LOADING });
  if (state.revisions.revisionsDisplayedCourseSpecific.length < state.revisions.courseScopedRevisions.length) {
    // no need to fetch new revisions
    return dispatch({
      type: 'INCREASE_LIMIT_COURSE_SPECIFIC'
    });
  }
  return (
    fetchRevisionsCourseSpecificPromise(course, users, state.revisions.last_date_course_specific ?? course.last)
      .then((resp) => {
        dispatch({
          type: RECEIVE_COURSE_SCOPED_REVISIONS,
          data: resp,
          limit: limit
        });
        // Now that we received the revisions data, query wikidata.org for the labels
        // of any Wikidata entries that are among the revisions.
        fetchWikidataLabelsForRevisions(resp.course.revisions, dispatch);
      })
      .catch(response => (dispatch({ type: API_FAIL, data: response })))
  );
};
export const sortRevisions = key => ({ type: SORT_REVISIONS, key: key });
