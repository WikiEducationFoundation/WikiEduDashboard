import { INITIALIZE, SET_VALID, SET_INVALID } from "../constants";

export const initialize = (key, message) => {
  return {
    type: INITIALIZE,
    data: {
      key: key,
      message: message
    }
  };
};

export const setValid = (key, quiet = false) => {
  return {
    type: SET_VALID,
    data: {
      key: key,
      quiet: quiet
    }
  };
};

export const setInvalid = (key, message, quiet = false) => {
  return {
    type: SET_INVALID,
    data: {
      key: key,
      message: message,
      quiet: quiet
    }
  };
};
