
import {
  RECEIVE_REVISIONS,
  REVISIONS_LOADING,
  RECEIVE_COURSE_SCOPED_REVISIONS,
  COURSE_SCOPED_REVISIONS_LOADING,
  SORT_REVISIONS,
  API_FAIL
} from '../constants';
import { fetchWikidataLabelsForRevisions } from './wikidata_actions';
import logErrorMessage from '../utils/log_error_message';
import request from '../utils/request';
import { fetchRevisionsFromUsers } from '../utils/mediawiki_revisions_utils';
import { fetchRevisionsAndReferences } from './media_wiki_revisions_actions';
import { sortRevisionsByDate } from '../utils/revision_utils';

const fetchRevisionsPromise = async (course, limit, isCourseScoped, users, last_date, lastRevisions, dispatch) => {
  if (!isCourseScoped) {
    const { revisions, last_date: new_last_date } = await fetchRevisionsFromUsers(course, users, 7, last_date);
    if (lastRevisions.length) {
      course.revisions = lastRevisions.concat(revisions);
    } else {
      course.revisions = revisions;
    }
    course.revisions = sortRevisionsByDate(course.revisions);

    // we don't await this. When the assessments/references get laoded, the action is dispatched
    fetchRevisionsAndReferences(revisions, dispatch);
    return { course, last_date: new_last_date };
  }
  const response = await request(`/courses/${course.slug}/revisions.json?limit=${limit}&course_scoped=${isCourseScoped}`);
  if (!response.ok) {
    logErrorMessage(response);
    const data = await response.text();
    response.responseText = data;
    throw response;
  }
  return response.json();
};

export const fetchRevisions = (course, limit, isCourseScoped = false) => async (dispatch, getState) => {
  let actionType;
  if (isCourseScoped) {
    actionType = RECEIVE_COURSE_SCOPED_REVISIONS;
    dispatch({ type: COURSE_SCOPED_REVISIONS_LOADING });
  } else {
    actionType = RECEIVE_REVISIONS;
    dispatch({ type: REVISIONS_LOADING });
  }
  const state = getState();
  const users = state.users.users;
  if (users.length === 0) {
    course.revisions = [];
    dispatch({
      type: actionType,
      data: { course },
      limit: limit
    });
    return;
  }
  return (
    fetchRevisionsPromise(course, limit, isCourseScoped, users, state.revisions.last_date, state.revisions.revisions, dispatch)
      .then((resp) => {
        dispatch({
          type: actionType,
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
