import { RECEIVE_USER_REVISIONS } from '../constants';

const initialState = {};

export default function userRevisions(state = initialState, action) {
  switch (action.type) {
    case RECEIVE_USER_REVISIONS: {
      // Merge wiki information, so that titles
      // can correctly show
      const revisions = action.revisions.map(rev => ({
        ...rev,
        wiki: {
          language: action.wiki.language,
          project: action.wiki.project
        },
        article: {
          title: rev.title,
          language: action.wiki.language,
          project: action.wiki.project
        }
      }));

      return {
        ...state,
        [action.username]: revisions
      };
    }
    default:
      return state;
  }
}
