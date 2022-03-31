import {
  RECEIVE_REVISIONS,
  REVISIONS_LOADING,
  RECEIVE_COURSE_SCOPED_REVISIONS,
  COURSE_SCOPED_REVISIONS_LOADING,
  SORT_REVISIONS,
  RECEIVE_REFERENCES,
  RECEIVE_ASSESSMENTS
} from '../constants';
import { sortByKey } from '../utils/model_utils';
import moment from 'moment';

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
  last_date: moment().format(),
};

const isLimitReachedCourseSpecific = (revs, limit) => {
  return (revs.length < limit);
};

const isLimitReached = (course_start, last_date) => {
  return moment(course_start).isAfter(moment(last_date)) || moment(last_date).isBefore(moment().subtract(5, 'years'));
};

export default function revisions(state = initialState, action) {
  switch (action.type) {
    case RECEIVE_REFERENCES: {
      const newState = { ...state };
      const revisionsArray = newState.revisions;
      const referencesAdded = action.data.referencesAdded;
      newState.revisions = revisionsArray.map((revision) => {
        return { references_added: referencesAdded?.[revision.revid] ?? 0, ...revision };
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
      return newState;
    }
    case RECEIVE_REVISIONS:
      return {
        ...state,
        revisions: action.data.course.revisions,
        limitReached: isLimitReached(action.data.course.start, state.last_date),
        revisionsLoaded: true,
        last_date: action.data.last_date
      };
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

      const sortedRevisions = sortByKey(state.revisions, action.key, null, desc, absolute);
      const sortedCourseScopedRevisions = sortByKey(state.courseScopedRevisions, action.key, null, desc, absolute);
      return { ...state,
        revisions: sortedRevisions.newModels,
        courseScopedRevisions: sortedCourseScopedRevisions.newModels,
        sort: {
          sortKey: desc ? null : action.key,
          key: action.key
        }
      };
    }
    default:
      return state;
  }
}
