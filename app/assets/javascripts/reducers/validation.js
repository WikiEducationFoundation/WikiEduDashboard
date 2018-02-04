import { INITIALIZE, SET_VALID, SET_INVALID, CHECK_SERVER } from "../constants";

const initialState = {
  validations: {},
  errorQueue: []
};

function __in__(needle, haystack) {
  return haystack.indexOf(needle) >= 0;
}

const setValidation = function (key, valid, message, changed = true, quiet = false, state) {
  const newState = { ...state };
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
  if (!quiet) { return newState; }
};


export default function validation(state = initialState, action) {
  const { data } = action;

  switch (action.type) {
      case INITIALIZE: {
        if (!state.validations[data.key]) {
          return setValidation(data.key, false, data.message, false, true, state);
        }
        return state;
      }
      case SET_VALID: {
        return setValidation(data.key, true, null, true, data.quiet, state);
      }
      case SET_INVALID: {
        return setValidation(data.key, false, data.message, true, data.quiet, state);
      }
      case CHECK_SERVER: {
        return setValidation(data.key, !data.message, data.message, state);
      }
      default:
        return state;
    }
}
