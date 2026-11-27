import { uniqBy } from 'lodash-es';
import { RECEIVE_STUDENT_ARTICLES, RECEIVE_MORE_STUDENT_ARTICLES } from '../constants';

// Articles edited by one student, kept per student id. These are kept apart from
// state.articles.articles on purpose: mixing them in would make the course-wide
// "See more" skip articles.
const initialState = {};

export default function studentArticles(state = initialState, action) {
  switch (action.type) {
    case RECEIVE_STUDENT_ARTICLES: {
      const page = action.data.course.articles;
      return {
        ...state,
        [action.userId]: {
          articles: page,
          // A full page means there may be more; a short page means we are done.
          limitReached: page.length < action.pageSize
        }
      };
    }
    case RECEIVE_MORE_STUDENT_ARTICLES: {
      const page = action.data.course.articles;
      const current = state[action.userId]?.articles || [];
      return {
        ...state,
        [action.userId]: {
          articles: uniqBy([...current, ...page], article => article.articles_course_id),
          limitReached: page.length < action.pageSize
        }
      };
    }
    default:
      return state;
  }
}
