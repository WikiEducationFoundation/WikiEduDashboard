import { reject } from 'lodash-es';
import { sortByKey } from '../utils/model_utils';
import { RECEIVE_ASSIGNMENTS, ADD_ASSIGNMENT, DELETE_ASSIGNMENT, UPDATE_ASSIGNMENT, LOADING_ASSIGNMENTS } from '../constants';

const initialState = {
  assignments: [],
  sortKey: null,
  loading: true,
  lastRequestTimestamp: 0 // UNIX timestamp of last request - in milliseconds
};

const SORT_DESCENDING = {};

export default function assignments(state = initialState, action) {
  switch (action.type) {
    case RECEIVE_ASSIGNMENTS: {
      const dataAssignments = action.data.course.assignments;
      // Initial sorting by article title
      const sortedModel = sortByKey(dataAssignments, 'article_title', state.sortKey, SORT_DESCENDING.article_title);
      return {
        assignments: sortedModel.newModels,
        sortKey: sortedModel.newKey,
        loading: false,
        lastRequestTimestamp: Date.now()
      };
    }
    case ADD_ASSIGNMENT: {
      const newAssignment = action.data;
<<<<<<< HEAD
      const assignmentExists = state.assignments.some(
        assignment => assignment.id === newAssignment.id
      );

      if (assignmentExists) {
        return state;
      }
=======
>>>>>>> f3815a4f0 (Done)
      const updatedAssignments = [...state.assignments, newAssignment];
      return { ...state, assignments: updatedAssignments };
    }
    case DELETE_ASSIGNMENT: {
      const updatedAssignments = reject(state.assignments, { id: action.data.assignmentId });
      return { ...state, assignments: updatedAssignments };
    }
    case UPDATE_ASSIGNMENT: {
      const updatedAssignment = action.data.assignment;
      const nonupdatedAssignments = reject(state.assignments, { id: updatedAssignment.id });
      return { ...state, assignments: [...nonupdatedAssignments, updatedAssignment] };
    }
    case LOADING_ASSIGNMENTS: {
      return { ...state, loading: true };
    }
    default:
      return state;
  }
}
