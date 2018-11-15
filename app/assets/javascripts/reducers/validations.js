import { ADD_VALIDATION, SET_VALID, SET_INVALID, COURSE_EXISTS } from '../constants';

const initialState = {
  validations: {},
  errorQueue: []
};

function __in__(needle, haystack) {
  return haystack.indexOf(needle) >= 0;
}

const setValidation = function (key, valid, message, changed = true, state) {
  const newState = { validations: { ...state.validations }, errorQueue: [...state.errorQueue] };
  if (!valid && changed && !(__in__(key, newState.errorQueue))) { // key is invalid
    newState.errorQueue.push(key);
  } else if (valid && __in__(key, newState.errorQueue)) {
    newState.errorQueue.splice(newState.errorQueue.indexOf(key), 1);
  }
  newState.validations[key] = {
    valid,
    changed,
    message
  };
  return newState;
};

export default function validations(state = initialState, action) {
  switch (action.type) {
      case ADD_VALIDATION: {
        if (!state.validations[action.key]) {
          return setValidation(action.key, false, action.message, false, state);
        }
        return state;
      }
      case SET_VALID: {
        return setValidation(action.key, true, null, true, state);
      }
      case SET_INVALID: {
        return setValidation(action.key, false, action.message, true, state);
      }
      case COURSE_EXISTS: {
        return setValidation(action.key, !action.message, action.message, true, state);
      }
      default:
        return state;
    }
}
