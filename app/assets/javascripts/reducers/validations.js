import { ADD_VALIDATION, SET_VALID, SET_INVALID, COURSE_SLUG_EXISTS, COURSE_SLUG_OKAY, ACTIVATE_VALIDATIONS, RESET_VALIDATIONS } from '../constants';

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
    // This adds a validation, but without marking it 'changed'.
    // This means no error message gets added to the queue.
    case ADD_VALIDATION: {
      if (!state.validations[action.key]) {
        return setValidation(action.key, false, action.message, false, state);
      }
      return state;
    }
    // This adds error messages to the queue for any invalid validations.
    case ACTIVATE_VALIDATIONS: {
      let newState = { ...state };
      Object.keys(state.validations).forEach((key) => {
        const validation = state.validations[key];
        newState = setValidation(key, validation.valid, validation.message, true, newState);
      });
      return newState;
    }
    case SET_VALID: {
      return setValidation(action.key, true, null, true, state);
    }
    case SET_INVALID: {
      return setValidation(action.key, false, action.message, true, state);
    }
    case COURSE_SLUG_EXISTS: {
      return setValidation('exists', false, action.message, true, state);
    }
    case COURSE_SLUG_OKAY: {
      return setValidation('exists', true, null, true, state);
    }
    case RESET_VALIDATIONS: {
      return initialState;
    }
    default:
      return state;
  }
}
