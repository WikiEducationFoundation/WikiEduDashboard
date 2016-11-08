import McFly from 'mcfly';
let Flux            = new McFly();
import BlockStore from './block_store.js';
import GradeableStore from './gradeable_store.js';


// Data
let _weeks = {};
let _persisted = {};
let _editableWeekId = 0;
let _isLoading = true;


// Utilities
let setWeeks = function(data, persisted=false) {
  for (let i = 0; i < data.length; i++) {
    let week = data[i];
    _weeks[week.id] = week;
    if (persisted) { _persisted[week.id] = $.extend(true, {}, week); }
  }
  _isLoading = false;
  return WeekStore.emitChange();
};

let setWeek = function(data) {
  _weeks[data.id] = data;
  return WeekStore.emitChange();
};

let addWeek = () =>
  setWeek({
    id: Date.now(), // could THEORETICALLY collide but highly unlikely
    is_new: true, // remove ids from objects with is_new when persisting
    blocks: []
  })
;

let removeWeek = function(week_id) {
  delete _weeks[week_id];
  return WeekStore.emitChange();
};

let setEditableWeekId = function(week_id) {
  _editableWeekId = week_id;
  return WeekStore.emitChange();
};

// Store
var WeekStore = Flux.createStore({
  getLoadingStatus() {
    return _isLoading;
  },
  getWeek(week_id) {
    return _weeks[week_id];
  },
  getWeeks() {
    let week_list = [];
    let iterable = Object.keys(_weeks);
    for (let i = 0; i < iterable.length; i++) {
      let week_id = iterable[i];
      week_list.push(_weeks[week_id]);
    }
    return week_list;
  },
  restore() {
    _weeks = $.extend(true, {}, _persisted);
    return WeekStore.emitChange();
  },
  getEditableWeekId() {
    return _editableWeekId;
  },
  clearEditableWeekId() {
    setEditableWeekId(null);
    return WeekStore.emitChange();
  }
}
, function(payload) {
  let { data } = payload;
  switch(payload.actionType) {
    case 'RECEIVE_TIMELINE': case 'SAVED_TIMELINE': case 'WIZARD_SUBMITTED':
      Flux.dispatcher.waitFor([BlockStore.dispatcherID, GradeableStore.dispatcherID]);
      _weeks = {};
      setWeeks(data.course.weeks, true);
      break;
    case 'ADD_WEEK':
      addWeek();
      break;
    case 'UPDATE_WEEK':
      setWeek(data.week);
      break;
    case 'DELETE_WEEK':
      removeWeek(data.week_id);
      break;
    case 'SET_WEEK_EDITABLE':
      setEditableWeekId(data.week_id);
      break;
  }
  return true;
});

export default WeekStore;
