import McFly from 'mcfly';
const Flux = new McFly();

const ValidationActions = Flux.createActions({
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
