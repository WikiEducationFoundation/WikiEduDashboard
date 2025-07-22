import { RECEIVE_USER_REVISIONS, API_FAIL } from '../constants';
import { fetchLatestRevisionsForUser } from '../utils/mediawiki_revisions_utils';

export const fetchUserRevisions = (course, user) => (dispatch, getState) => {
  // Don't refetch a user's revisions if they are already in the store.
  if (getState().userRevisions[user.username]) { return; }

  return (
    fetchLatestRevisionsForUser(user.username, course.home_wiki)
      .then((resp) => {
        dispatch({
          type: RECEIVE_USER_REVISIONS,
          revisions: resp,
          username: user.username,
          wiki: course.home_wiki
        });
      })
      .catch(response => (dispatch({ type: API_FAIL, data: response })))
  );
};

