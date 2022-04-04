import {
  RECEIVE_REVISIONS,
  REVISIONS_LOADING,
  RECEIVE_COURSE_SCOPED_REVISIONS,
  COURSE_SCOPED_REVISIONS_LOADING,
  SORT_REVISIONS,
  RECEIVE_REFERENCES,
  RECEIVE_ASSESSMENTS,
  INCREASE_LIMIT
} from '../constants';
import { sortByKey } from '../utils/model_utils';
import moment from 'moment';

// this is the max number of revisions we will add to the table when there's a new fetch request
const REVISIONS_INITIAL = 200;

// this is the max number of revisions we will add to the table when no new fetch request is needed
const REVISIONS_INCREMENT = 50;


const initialState = {
  revisions: [],
  limitReached: false,
  courseScopedRevisions: [],
  courseScopedLimit: 50,
  courseScopedLimitReached: false,
  sort: {
    key: null,
    sortKey: null,
  },
  revisionsLoaded: false,
  courseScopedRevisionsLoaded: false,
  last_date: moment().utc().format(),
  revisionsDisplayed: [],
};

const isLimitReachedCourseSpecific = (revs, limit) => {
  return (revs.length < limit);
};

const isLimitReached = (course_start, last_date) => {
  return moment(course_start).isAfter(moment(last_date)) || moment(last_date).isBefore(moment().subtract(5, 'years'));
};

export default function revisions(state = initialState, action) {
  switch (action.type) {
    case INCREASE_LIMIT: {
      let revisionsDisplayed = state.revisionsDisplayed.concat(
        state.revisions.slice(
            state.revisionsDisplayed.length, state.revisionsDisplayed.length + REVISIONS_INCREMENT
          )
      );
      // since newly fetched revisions are sorted by date(descending) if the user changes the sorting parameter and then loads
      // more revisions, the table would not be sorted correctly. The new revisions would just be appended to the end
      // the following condition checks if we should sort the revisions
      if ((state.sort.key !== 'date' && state.sort.key !== null) || (state.sort.key === 'date' && state.sort.sortKey !== null)) {
        // either the sorting is on the basis of date(ascending) or any other parameter(ascending or descending)
        // state.sort.key !== null ensures that this doesn't run on the first load
        const desc = state.sort.sortKey === null;
        const absolute = state.sort.key === 'characters';
        revisionsDisplayed = sortByKey(revisionsDisplayed, state.sort.key, null, desc, absolute).newModels;
      }
      return {
        ...state,
        revisionsDisplayed,
        revisionsLoaded: true
      };
    }
    case RECEIVE_REFERENCES: {
      const newState = { ...state };
      const revisionsArray = newState.revisions;
      const referencesAdded = action.data.referencesAdded;
      newState.revisions = revisionsArray.map((revision) => {
        return { references_added: referencesAdded?.[revision?.revid], ...revision };
      });
      newState.revisionsDisplayed = state.revisionsDisplayed.map((revision) => {
        return { references_added: referencesAdded?.[revision?.revid], ...revision };
      });
      return newState;
    }
    case RECEIVE_ASSESSMENTS: {
      const newState = { ...state };
      const revisionsArray = newState.revisions;
      const pageAssessments = action.data.assessments;
      newState.revisions = revisionsArray.map((revision) => {
        return {
          rating_num: pageAssessments?.[revision.revid]?.rating_num,
          pretty_rating: pageAssessments?.[revision.revid]?.pretty_rating,
          rating: pageAssessments?.[revision.revid]?.rating,
          ...revision
        };
      });
      newState.revisionsDisplayed = state.revisionsDisplayed.map((revision) => {
        return {
          rating_num: pageAssessments?.[revision.revid]?.rating_num,
          pretty_rating: pageAssessments?.[revision.revid]?.pretty_rating,
          rating: pageAssessments?.[revision.revid]?.rating,
          ...revision
        };
      });
      return newState;
    }
    case RECEIVE_REVISIONS: {
      let revisionsDisplayed = state.revisionsDisplayed.concat(
        action.data.course.revisions.slice(0, REVISIONS_INITIAL)
      );
      if ((state.sort.key !== 'date' && state.sort.key !== null) || (state.sort.key === 'date' && state.sort.sortKey !== null)) {
        const desc = state.sort.sortKey === null;
        const absolute = state.sort.key === 'characters';
        revisionsDisplayed = sortByKey(revisionsDisplayed, state.sort.key, null, desc, absolute).newModels;
      }

      return {
        ...state,
        revisions: state.revisions.concat(action.data.course.revisions),
        limitReached: isLimitReached(action.data.course.start, state.last_date),
        revisionsLoaded: true,
        last_date: action.data.last_date,
        revisionsDisplayed
      };
    }
    case RECEIVE_COURSE_SCOPED_REVISIONS:
      return {
        ...state,
        courseScopedRevisions: action.data.course.revisions,
        courseScopedLimit: action.limit,
        courseScopedLimitReached: isLimitReachedCourseSpecific(action.data.course.revisions, action.limit),
        courseScopedRevisionsLoaded: true
      };
    case REVISIONS_LOADING:
      return {
        ...state,
        revisionsLoaded: false,
      };
    case COURSE_SCOPED_REVISIONS_LOADING:
      return {
        ...state,
        courseScopedRevisionsLoaded: false
      };
    case SORT_REVISIONS: {
      const absolute = action.key === 'characters';
      const desc = action.key === state.sort.sortKey;

      const sortedRevisions = sortByKey(state.revisionsDisplayed, action.key, null, desc, absolute);
      const sortedCourseScopedRevisions = sortByKey(state.courseScopedRevisions, action.key, null, desc, absolute);
      return { ...state,
        revisionsDisplayed: sortedRevisions.newModels,
        courseScopedRevisions: sortedCourseScopedRevisions.newModels,
        sort: {
          sortKey: desc ? null : action.key,
          key: action.key
        },
      };
    }
    default:
      return state;
  }
}
