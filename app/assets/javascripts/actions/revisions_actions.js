import { RECEIVE_REVISIONS, RECEIVE_COURSE_SCOPED_REVISIONS, SORT_REVISIONS, API_FAIL } from '../constants';
import { fetchWikidataLabelsForRevisions } from './wikidata_actions';
import logErrorMessage from '../utils/log_error_message';

const fetchRevisionsPromise = (courseId, limit, isCourseScoped) => {
  return new Promise((res, rej) => {
    return $.ajax({
      type: 'GET',
      url: `/courses/${courseId}/revisions.json?limit=${limit}&course_scoped=${isCourseScoped}`,
      success(data) {
        return res(data);
      }
    })
    .fail((obj) => {
      logErrorMessage(obj);
      return rej(obj);
    });
  });
};

export const fetchRevisions = (courseId, limit, isCourseScoped = false) => (dispatch) => {
  const actionType = isCourseScoped ? RECEIVE_COURSE_SCOPED_REVISIONS : RECEIVE_REVISIONS;
  return (
    fetchRevisionsPromise(courseId, limit, isCourseScoped)
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
