import { RECEIVE_USER_REVISIONS } from '../constants';

const initialState = {};

export default function userRevisions(state = initialState, action) {
  switch (action.type) {
    case RECEIVE_USER_REVISIONS: {
      // Merge project information into article, so that titles
      // can correctly show
      const revisions = action.data.course.revisions.map(rev => ({
        ...rev,
        article: {
          ...rev.article,
          project: rev.wiki.project
        }
      }));

      return {
        ...state,
        [action.userId]: revisions
      };
    }
    default:
      return state;
  }
}
