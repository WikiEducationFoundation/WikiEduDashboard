import McFly from 'mcfly';
import { ADD_VALIDATION, SET_VALID, SET_INVALID } from '../constants';

const Flux = new McFly();

export const addValidation = (key, message) => (dispatch) => {
  dispatch({ type: ADD_VALIDATION, key, message });
  ValidationActions.initialize(key, message);
};

export const setValid = (key, quiet = false) => (dispatch) => {
  dispatch({ type: SET_VALID, key, quiet });
  ValidationActions.setValid(key, quiet);
};

export const setInvalid = (key, message, quiet = false) => (dispatch) => {
  dispatch({ type: SET_INVALID, key, message, quiet });
  ValidationActions.setInvalid(key, message, quiet);
};

const ValidationActions = Flux.createActions({
  // Workaround for dispatching a McFly action from a Redux action
  dispatchAction(action) {
    return action;
  },

  initialize(key, message) {
    return {
      actionType: 'INITIALIZE',
      data: {
        key,
        message
      }
    };
  },

  setValid(key, quiet = false) {
    return {
      actionType: 'SET_VALID',
      data: {
        key,
        quiet
      }
    };
  },

  setInvalid(key, message, quiet = false) {
    return {
      actionType: 'SET_INVALID',
      data: {
        key,
        message,
        quiet
      }
    };
  }
});

export default ValidationActions;
