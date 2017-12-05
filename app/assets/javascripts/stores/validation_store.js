import McFly from 'mcfly';
const Flux = new McFly();

// Data
const _validations = {};
const _errorQueue = [];

// Utilities
const setValidation = function (key, valid, message, changed = true, quiet = false) {
  if (!valid && changed && !(__in__(key, _errorQueue))) { // key is invalid
    _errorQueue.push(key);
  } else if (valid && __in__(key, _errorQueue)) {
    _errorQueue.splice(_errorQueue.indexOf(key), 1);
  }
  _validations[key] = {
    valid,
    changed,
    message
  };
  if (!quiet) { return ValidationStore.emitChange(); }
};


// Store
const ValidationStore = Flux.createStore(
  {
    isValid() {
      let valid = true;
      const iterable = Object.keys(_validations);
      for (let i = 0; i < iterable.length; i++) {
        const key = iterable[i];
        if (!_validations[key].changed && !_validations[key].valid) {
          setValidation(key, false, _validations[key].message, true);
        }
        valid = valid && _validations[key].valid;
      }
      return valid;
    },
    getValidations() {
      return _validations;
    },
    getValidation(key) {
      if ((_validations[key]) && _validations[key].changed) {
        return _validations[key].valid;
      }
      return true;
    },
    firstMessage() {
      if (_errorQueue.length > 0) {
        return _validations[_errorQueue[0]].message;
      }
      return null;
    }
  }
  , (payload) => {
    const { data } = payload;
    switch (payload.actionType) {
      case 'INITIALIZE':
        if (!_validations[data.key]) {
          setValidation(data.key, false, data.message, false, true);
        }
        break;
      case 'SET_VALID':
        setValidation(data.key, true, null, true, data.quiet);
        break;
      case 'SET_INVALID':
        setValidation(data.key, false, data.message, true, data.quiet);
        break;
      case 'CHECK_SERVER':
        setValidation(data.key, !data.message, data.message);
        break;
      default:
      // no default
    }
    return true;
  }
);

ValidationStore.setMaxListeners(0);

export default ValidationStore;

function __in__(needle, haystack) {
  return haystack.indexOf(needle) >= 0;
}
