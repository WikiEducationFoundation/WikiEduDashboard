import McFly from 'mcfly';
let Flux            = new McFly();
import ServerActions from '../actions/server_actions.js';


// Data
let _lookups = {};


// Utilities
let addLookups = function(key, values) {
  _lookups[key] = values;
  return LookupStore.emitChange();
};


// Store
var LookupStore = Flux.createStore({
  getLookups(model) {
    if (_lookups.hasOwnProperty(model)) {
      return _lookups[model];
    } else {
      ServerActions.fetchLookups(model);
      return [];
    }
  }
}
, function(payload) {
  let { data } = payload;
  switch(payload.actionType) {
    case 'RECEIVE_LOOKUPS':
      addLookups(data.model, data.values);
      break;
  }
  if (payload.actionType.indexOf("RECEIVE") > 0) {
    let model = (payload.actionType.match(/RECEIVE_(.*?)S/))[1].toLowerCase();
    if (__in__(model, Object.keys(_lookups))) { ServerActions.fetchLookups(model); }
  }
  return true;
});

LookupStore.setMaxListeners(0);

export default LookupStore;

function __in__(needle, haystack) {
  return haystack.indexOf(needle) >= 0;
}