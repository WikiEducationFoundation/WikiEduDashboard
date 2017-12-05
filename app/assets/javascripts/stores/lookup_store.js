import McFly from 'mcfly';
const Flux = new McFly();
import ServerActions from '../actions/server_actions.js';

function __in__(needle, haystack) {
  return haystack.indexOf(needle) >= 0;
}

// Data
const _lookups = {};


// Utilities
const addLookups = function (key, values) {
  _lookups[key] = values;
  return LookupStore.emitChange();
};


// Store
const LookupStore = Flux.createStore(
  {
    getLookups(model) {
      if (_lookups.hasOwnProperty(model)) {
        return _lookups[model];
      }
      ServerActions.fetchLookups(model);
      return [];
    }
  }
  , (payload) => {
    const { data } = payload;
    switch (payload.actionType) {
      case 'RECEIVE_LOOKUPS':
        addLookups(data.model, data.values);
        break;
      default:
      // no default
    }
    if (payload.actionType.indexOf('RECEIVE') > 0) {
      const model = (payload.actionType.match(/RECEIVE_(.*?)S/))[1].toLowerCase();
      if (__in__(model, Object.keys(_lookups))) { ServerActions.fetchLookups(model); }
    }
    return true;
  }
);

LookupStore.setMaxListeners(0);

export default LookupStore;
